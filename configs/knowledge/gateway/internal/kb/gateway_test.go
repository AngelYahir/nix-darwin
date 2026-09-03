package kb

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"
)

const testPolicy = `[profiles.engineering]
allowed_domains = ["work1", "work2", "personal"]
allowed_types = ["architecture", "decision", "pattern", "lesson", "incident", "runbook", "reference", "sdk"]
route = "project"

[profiles.personal]
allowed_domains = ["personal", "languages"]
allowed_types = ["grammar", "vocabulary", "expression", "mistake", "listening", "reading", "culture", "reference"]
route = "personal"

[routing]
projects = "Projects"

[routing.domains]
work1 = "Work/Work1"
work2 = "Work/Work2"
personal = "Personal"
languages = "Languages"

[routing.types]
architecture = "Architecture"
decision = "Decisions"
pattern = "Patterns"
lesson = "Lessons"
incident = "Incidents"
runbook = "Runbooks"
reference = "Reference"
sdk = "SDK"
grammar = "Grammar"
vocabulary = "Vocabulary"
expression = "Expressions"
mistake = "Mistakes"
listening = "Listening"
reading = "Reading"
culture = "Culture"
`

func TestGatewayAcceptance(t *testing.T) {
	t.Run("1 create note", func(t *testing.T) {
		gateway, vault, request := testSetup(t)
		response, err := gateway.Upsert(request)
		if err != nil || response.Result != "published" {
			t.Fatalf("response=%+v err=%v", response, err)
		}
		path := onlyMatch(t, vault, request.KBID)
		content := read(t, path)
		if !strings.Contains(content, managedStart) || !strings.Contains(content, request.Body) {
			t.Fatal("created note is missing managed content")
		}
	})

	t.Run("2 update same kb_id", func(t *testing.T) {
		gateway, vault, request := testSetup(t)
		mustUpsert(t, gateway, request)
		request.Body = "updated durable lesson"
		response, err := gateway.Upsert(request)
		if err != nil || response.Result != "updated" {
			t.Fatalf("response=%+v err=%v", response, err)
		}
		content := read(t, onlyMatch(t, vault, request.KBID))
		if !strings.Contains(content, request.Body) || strings.Contains(content, "original durable lesson") {
			t.Fatal("managed body was not replaced")
		}
	})

	t.Run("3 manual content survives update", func(t *testing.T) {
		gateway, vault, request := testSetup(t)
		mustUpsert(t, gateway, request)
		path := onlyMatch(t, vault, request.KBID)
		content := read(t, path)
		content = strings.Replace(content, "---\n"+managedStart, "user_note: keep\n---\nmanual before\n"+managedStart, 1) + "\nmanual after\n"
		write(t, path, content)
		request.Body = "replacement"
		mustUpsert(t, gateway, request)
		updated := read(t, path)
		for _, wanted := range []string{"user_note: keep", "manual before", "manual after", "replacement"} {
			if !strings.Contains(updated, wanted) {
				t.Fatalf("manual or managed content lost: %q", wanted)
			}
		}
	})

	t.Run("4 duplicate kb_id fails safely", func(t *testing.T) {
		gateway, vault, request := testSetup(t)
		first := managedFixture(request.KBID, "first secret")
		second := managedFixture(request.KBID, "second secret")
		write(t, filepath.Join(vault, "first.md"), first)
		write(t, filepath.Join(vault, "second.md"), second)
		_, err := gateway.Upsert(request)
		if err == nil || err.Error() != "duplicate kb_id" {
			t.Fatalf("expected duplicate error, got %v", err)
		}
		if read(t, filepath.Join(vault, "first.md")) != first || read(t, filepath.Join(vault, "second.md")) != second {
			t.Fatal("duplicate notes were modified")
		}
	})

	t.Run("5 unknown project fails", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		request.ProjectKey = RepositoryKey(filepath.Join(t.TempDir(), "unknown"))
		_, err := gateway.Upsert(request)
		if err == nil || !strings.Contains(err.Error(), "unknown project") {
			t.Fatalf("expected unknown project error, got %v", err)
		}
	})

	t.Run("6 engineering cannot route to languages", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		request.Domain = "languages"
		_, err := gateway.Upsert(request)
		if err == nil || !strings.Contains(err.Error(), "not allowed") {
			t.Fatalf("expected forbidden domain error, got %v", err)
		}
	})

	t.Run("7 invalid type fails", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		request.Type = "temporary-debug-log"
		_, err := gateway.Upsert(request)
		if err == nil || !strings.Contains(err.Error(), "invalid type") {
			t.Fatalf("expected invalid type error, got %v", err)
		}
	})

	t.Run("8 path traversal fails", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		request.KBID = "../escape"
		_, err := gateway.Upsert(request)
		if err == nil || !strings.Contains(err.Error(), "invalid kb_id") {
			t.Fatalf("expected invalid kb_id error, got %v", err)
		}
	})

	t.Run("9 malformed request fails", func(t *testing.T) {
		gateway, _, _ := testSetup(t)
		response := protocolRequest(t, gateway, `{not-json`)
		if response.OK || response.Error == "" {
			t.Fatalf("malformed request was accepted: %+v", response)
		}
	})

	t.Run("10 missing vault config fails clearly", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		if err := os.Remove(gateway.Paths.Local); err != nil {
			t.Fatal(err)
		}
		_, err := gateway.Upsert(request)
		if err == nil || !strings.Contains(err.Error(), "kb init --vault") {
			t.Fatalf("expected initialization guidance, got %v", err)
		}
	})

	t.Run("11 project-auto resolves registered repository", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		projects, err := LoadProjects(gateway.Paths.Projects)
		if err != nil || len(projects) != 1 {
			t.Fatalf("projects=%+v err=%v", projects, err)
		}
		nested := filepath.Join(projects[0].Repo, "nested")
		if err := os.MkdirAll(nested, 0o755); err != nil {
			t.Fatal(err)
		}
		root, err := RepositoryRoot(nested)
		if err != nil || root != projects[0].Repo {
			t.Fatalf("root=%q err=%v", root, err)
		}
		project, found := FindProjectByKey(projects, RepositoryKey(root))
		if err != nil || !found || project.Domain != request.Domain || project.Project != request.Project {
			t.Fatalf("project=%+v found=%t err=%v", project, found, err)
		}
	})

	t.Run("12 response never contains existing note body", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		request.Body = "SENSITIVE-BODY-NEVER-RETURN"
		response := mustUpsert(t, gateway, request)
		encoded, err := json.Marshal(response)
		if err != nil || bytes.Contains(encoded, []byte(request.Body)) {
			t.Fatalf("response leaked note body: %s", encoded)
		}
	})

	t.Run("13 logs do not contain note body", func(t *testing.T) {
		gateway, _, request := testSetup(t)
		var logs bytes.Buffer
		gateway.Logger = log.New(&logs, "", 0)
		request.Body = "SENSITIVE-LOG-BODY"
		mustUpsert(t, gateway, request)
		if strings.Contains(logs.String(), request.Body) {
			t.Fatalf("log leaked note body: %s", logs.String())
		}
		for _, field := range []string{"operation=", "kb_id=", "success=true"} {
			if !strings.Contains(logs.String(), field) {
				t.Fatalf("log missing %s: %s", field, logs.String())
			}
		}
	})

	t.Run("14 atomic update leaves no partial file", func(t *testing.T) {
		dir := t.TempDir()
		path := filepath.Join(dir, "note.md")
		write(t, path, "old")
		if err := atomicWrite(path, []byte("complete replacement"), 0o644, true); err != nil {
			t.Fatal(err)
		}
		if read(t, path) != "complete replacement" {
			t.Fatal("atomic replacement is incomplete")
		}
		matches, err := filepath.Glob(filepath.Join(dir, ".kb-tmp-*"))
		if err != nil || len(matches) != 0 {
			t.Fatalf("temporary files remain: %v err=%v", matches, err)
		}
	})

	t.Run("15 second publish does not create a duplicate", func(t *testing.T) {
		gateway, vault, request := testSetup(t)
		mustUpsert(t, gateway, request)
		mustUpsert(t, gateway, request)
		matches, err := findKBID(vault, request.KBID)
		if err != nil || len(matches) != 1 {
			t.Fatalf("matches=%v err=%v", matches, err)
		}
	})

	t.Run("16 unmanaged note is not overwritten", func(t *testing.T) {
		gateway, vault, request := testSetup(t)
		path := filepath.Join(vault, "manual.md")
		original := "---\nkb_id: " + strconv.Quote(request.KBID) + "\n---\nmanual content\n"
		write(t, path, original)
		_, err := gateway.Upsert(request)
		if err == nil || !strings.Contains(err.Error(), "not managed") {
			t.Fatalf("expected unmanaged error, got %v", err)
		}
		if read(t, path) != original {
			t.Fatal("unmanaged note was overwritten")
		}
	})
}

func testSetup(t *testing.T) (*Gateway, string, Request) {
	t.Helper()
	base := t.TempDir()
	vault := filepath.Join(base, "vault")
	repo := filepath.Join(base, "repo")
	for _, dir := range []string{vault, repo} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	command := exec.Command("git", "-C", repo, "init", "-q")
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("git init: %v: %s", err, output)
	}
	resolvedRepo, err := filepath.EvalSymlinks(repo)
	if err != nil {
		t.Fatal(err)
	}
	paths := Paths{
		Policy:   filepath.Join(base, "policy.toml"),
		Local:    filepath.Join(base, "local.toml"),
		Projects: filepath.Join(base, "projects.toml"),
	}
	write(t, paths.Policy, testPolicy)
	write(t, paths.Local, "vault_root = "+strconv.Quote(vault)+"\n")
	if err := WriteProjects(paths.Projects, []Project{{Repo: resolvedRepo, Domain: "work1", Project: "payments"}}); err != nil {
		t.Fatal(err)
	}
	gateway := &Gateway{Paths: paths, Now: func() time.Time {
		return time.Date(2026, 9, 3, 0, 0, 0, 0, time.UTC)
	}}
	return gateway, vault, Request{
		Operation:  "upsert",
		Profile:    "engineering",
		KBID:       "work1-payments-ledger-idempotency",
		Title:      "Ledger idempotency",
		Domain:     "work1",
		Project:    "payments",
		Type:       "lesson",
		Status:     "canonical",
		Body:       "original durable lesson",
		ProjectKey: RepositoryKey(resolvedRepo),
	}
}

func mustUpsert(t *testing.T, gateway *Gateway, request Request) Response {
	t.Helper()
	response, err := gateway.Upsert(request)
	if err != nil {
		t.Fatal(err)
	}
	return response
}

func onlyMatch(t *testing.T, vault, id string) string {
	t.Helper()
	matches, err := findKBID(vault, id)
	if err != nil || len(matches) != 1 {
		t.Fatalf("matches=%v err=%v", matches, err)
	}
	return matches[0]
}

func managedFixture(id, body string) string {
	return fmt.Sprintf("---\nkb_id: %s\nmanaged_by: %q\n---\n%s\n\n%s\n\n%s", strconv.Quote(id), "kb-gateway", managedStart, body, managedEnd)
}

func protocolRequest(t *testing.T, gateway *Gateway, payload string) Response {
	t.Helper()
	return gateway.handleRequest(strings.NewReader(payload))
}

func write(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func read(t *testing.T, path string) string {
	t.Helper()
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return string(content)
}
