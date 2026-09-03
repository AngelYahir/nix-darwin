package kb

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"
)

const (
	managedStart = "<!-- kb-gateway:managed:start -->"
	managedEnd   = "<!-- kb-gateway:managed:end -->"
	maxBodyBytes = 4 << 20
)

var kbIDPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$`)
var projectKeyPattern = regexp.MustCompile(`^[a-f0-9]{64}$`)

type Gateway struct {
	Paths  Paths
	Logger *log.Logger
	Now    func() time.Time
	mu     sync.Mutex // ponytail: one local writer; use per-kb_id locks only if throughput matters.
}

func (gateway *Gateway) Upsert(request Request) (response Response, err error) {
	gateway.mu.Lock()
	defer gateway.mu.Unlock()

	success := false
	defer func() { gateway.log(request, success) }()

	if request.Operation != "upsert" {
		return Response{}, errors.New("unsupported operation")
	}
	policy, err := LoadPolicy(gateway.Paths.Policy)
	if err != nil {
		return Response{}, err
	}
	profile, ok := policy.Profiles[request.Profile]
	if !ok {
		return Response{}, errors.New("invalid profile")
	}
	if !profile.AllowedDomains[request.Domain] {
		return Response{}, errors.New("domain is not allowed for this profile")
	}
	if !profile.AllowedTypes[request.Type] {
		return Response{}, errors.New("invalid type for this profile")
	}
	if !kbIDPattern.MatchString(request.KBID) {
		return Response{}, errors.New("invalid kb_id")
	}
	request.Title = strings.TrimSpace(request.Title)
	if request.Title == "" || len(request.Title) > 200 {
		return Response{}, errors.New("title is required and must be at most 200 bytes")
	}
	if len(request.Body) > maxBodyBytes {
		return Response{}, errors.New("note body is too large")
	}
	if strings.TrimSpace(request.Body) == "" {
		return Response{}, errors.New("note body is empty")
	}
	if strings.Contains(request.Body, managedStart) || strings.Contains(request.Body, managedEnd) {
		return Response{}, errors.New("note body contains reserved managed markers")
	}
	if request.Status == "" {
		request.Status = "canonical"
	}
	if request.Status != "canonical" && request.Status != "deprecated" && request.Status != "superseded" {
		return Response{}, errors.New("invalid status")
	}
	if err := validateSource(request.Source); err != nil {
		return Response{}, err
	}

	if profile.Route == "project" {
		if !projectKeyPattern.MatchString(request.ProjectKey) {
			return Response{}, errors.New("engineering publication requires a registered repository")
		}
		projects, err := LoadProjects(gateway.Paths.Projects)
		if err != nil {
			return Response{}, fmt.Errorf("project registry: %w", err)
		}
		registered, found := FindProjectByKey(projects, request.ProjectKey)
		if !found {
			return Response{}, errors.New("unknown project")
		}
		if request.Domain != registered.Domain || request.Project != registered.Project {
			return Response{}, errors.New("project metadata does not match registry")
		}
		if err := ValidateFragment(request.Project, "project"); err != nil {
			return Response{}, err
		}
	} else if request.Domain == "languages" {
		if err := ValidateFragment(request.Language, "language"); err != nil {
			return Response{}, err
		}
	}

	vaultRoot, err := LoadVaultRoot(gateway.Paths.Local)
	if err != nil {
		return Response{}, err
	}
	matches, err := findKBID(vaultRoot, request.KBID)
	if err != nil {
		return Response{}, errors.New("scan vault metadata failed")
	}
	if len(matches) > 1 {
		return Response{}, errors.New("duplicate kb_id")
	}

	result := "published"
	if len(matches) == 1 {
		if err := gateway.update(matches[0], request); err != nil {
			return Response{}, err
		}
		result = "updated"
	} else if err := gateway.create(vaultRoot, policy, profile, request); err != nil {
		return Response{}, err
	}

	success = true
	return Response{OK: true, Result: result, KBID: request.KBID}, nil
}

func (gateway *Gateway) create(root string, policy Policy, profile Profile, request Request) error {
	domainRoute, ok := policy.DomainRoutes[request.Domain]
	if !ok {
		return errors.New("domain has no route")
	}
	typeRoute, ok := policy.TypeRoutes[request.Type]
	if !ok {
		return errors.New("type has no route")
	}
	routes := []string{domainRoute}
	if profile.Route == "project" {
		routes = append(routes, policy.ProjectsFolder, safeSlug(request.Project), typeRoute)
	} else if request.Domain == "languages" {
		routes = append(routes, safeSlug(request.Language), typeRoute)
	} else {
		routes = append(routes, typeRoute)
	}
	dir, err := secureDir(root, routes...)
	if err != nil {
		return err
	}
	filename := safeSlug(request.Title) + "--" + safeSlug(request.KBID) + ".md"
	if filename == "--.md" {
		return errors.New("title and kb_id do not form a safe filename")
	}
	path := filepath.Join(dir, filename)
	if _, err := os.Lstat(path); err == nil {
		return errors.New("destination already exists")
	} else if !os.IsNotExist(err) {
		return fmt.Errorf("inspect destination: %w", err)
	}
	now := gateway.now().Format("2006-01-02")
	content := renderFrontmatter(request, now, now, nil) + renderManagedBody(request.Body)
	if err := atomicWrite(path, []byte(content), 0o644, false); err != nil {
		return errors.New("write note failed")
	}
	return nil
}

func (gateway *Gateway) update(path string, request Request) error {
	info, err := os.Lstat(path)
	if err != nil || !info.Mode().IsRegular() {
		return errors.New("managed note is not a regular file")
	}
	content, err := os.ReadFile(path)
	if err != nil {
		return errors.New("read managed note failed")
	}
	header, rest, err := splitFrontmatter(string(content))
	if err != nil || frontmatterValue(header, "managed_by") != "kb-gateway" ||
		strings.Count(rest, managedStart) != 1 || strings.Count(rest, managedEnd) != 1 {
		return errors.New("existing note is not managed by kb-gateway")
	}
	start := strings.Index(rest, managedStart)
	end := strings.Index(rest, managedEnd)
	if end < start {
		return errors.New("existing note has invalid managed markers")
	}
	created := frontmatterValue(header, "created")
	if created == "" {
		created = gateway.now().Format("2006-01-02")
	}
	updatedHeader := renderFrontmatter(request, created, gateway.now().Format("2006-01-02"), unmanagedFrontmatter(header))
	updatedBody := rest[:start] + renderManagedBody(request.Body) + rest[end+len(managedEnd):]
	if err := atomicWrite(path, []byte(updatedHeader+updatedBody), info.Mode().Perm(), true); err != nil {
		return errors.New("update note failed")
	}
	return nil
}

func (gateway *Gateway) now() time.Time {
	if gateway.Now != nil {
		return gateway.Now()
	}
	return time.Now()
}

func (gateway *Gateway) log(request Request, success bool) {
	if gateway.Logger == nil {
		return
	}
	gateway.Logger.Printf("operation=%q kb_id=%q domain=%q project=%q type=%q success=%t",
		request.Operation, request.KBID, request.Domain, request.Project, request.Type, success)
}

func ListenAndServe(paths Paths, logger *log.Logger) error {
	if err := os.MkdirAll(paths.StateDir, 0o700); err != nil {
		return fmt.Errorf("create state directory: %w", err)
	}
	if err := os.Chmod(paths.StateDir, 0o700); err != nil {
		return fmt.Errorf("secure state directory: %w", err)
	}
	if info, err := os.Lstat(paths.Socket); err == nil {
		if info.Mode()&os.ModeSocket == 0 {
			return errors.New("socket path exists and is not a socket")
		}
		if err := os.Remove(paths.Socket); err != nil {
			return fmt.Errorf("remove stale socket: %w", err)
		}
	} else if !os.IsNotExist(err) {
		return fmt.Errorf("inspect socket: %w", err)
	}
	listener, err := net.Listen("unix", paths.Socket)
	if err != nil {
		return err
	}
	defer listener.Close()
	defer os.Remove(paths.Socket)
	if err := os.Chmod(paths.Socket, 0o600); err != nil {
		return fmt.Errorf("secure socket: %w", err)
	}
	gateway := &Gateway{Paths: paths, Logger: logger}
	for {
		connection, err := listener.Accept()
		if err != nil {
			return err
		}
		go gateway.handleConn(connection)
	}
}

func (gateway *Gateway) handleConn(connection net.Conn) {
	defer connection.Close()
	_ = connection.SetReadDeadline(time.Now().Add(10 * time.Second))
	_ = json.NewEncoder(connection).Encode(gateway.handleRequest(connection))
}

func (gateway *Gateway) handleRequest(reader io.Reader) Response {
	response := Response{}
	data, err := io.ReadAll(io.LimitReader(reader, maxRequestBytes+1))
	if err == nil && len(data) > maxRequestBytes {
		err = errors.New("request is too large")
	}
	var request Request
	if err == nil {
		decoder := json.NewDecoder(bytes.NewReader(data))
		decoder.DisallowUnknownFields()
		if err = decoder.Decode(&request); err == nil {
			var extra any
			if second := decoder.Decode(&extra); second != io.EOF {
				err = errors.New("request must contain one JSON object")
			}
		}
	}
	if err == nil {
		response, err = gateway.Upsert(request)
	}
	if err != nil {
		response = Response{OK: false, KBID: request.KBID, Error: err.Error()}
		if request.Operation == "" {
			gateway.log(Request{Operation: "invalid"}, false)
		}
	}
	return response
}

func findKBID(root, id string) ([]string, error) {
	var matches []string
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.Type()&os.ModeSymlink != 0 {
			if entry.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		if entry.IsDir() || !strings.EqualFold(filepath.Ext(entry.Name()), ".md") {
			return nil
		}
		found, err := readFrontmatterID(path)
		if err != nil {
			return err
		}
		if found == id {
			matches = append(matches, path)
		}
		return nil
	})
	return matches, err
}

func readFrontmatterID(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer file.Close()
	scanner := bufio.NewScanner(io.LimitReader(file, 1<<20))
	if !scanner.Scan() || strings.TrimSpace(scanner.Text()) != "---" {
		return "", nil
	}
	for scanner.Scan() {
		line := scanner.Text()
		if strings.TrimSpace(line) == "---" {
			return "", nil
		}
		if strings.HasPrefix(line, "kb_id:") {
			return yamlValue(strings.TrimSpace(strings.TrimPrefix(line, "kb_id:"))), nil
		}
	}
	return "", scanner.Err()
}

func renderFrontmatter(request Request, created, updated string, extra []string) string {
	var output strings.Builder
	output.WriteString("---\n")
	fields := [][2]string{
		{"kb_id", request.KBID},
		{"title", request.Title},
		{"profile", request.Profile},
		{"domain", request.Domain},
	}
	if request.Project != "" {
		fields = append(fields, [2]string{"project", request.Project})
	}
	if request.Language != "" {
		fields = append(fields, [2]string{"language", request.Language})
	}
	fields = append(fields,
		[2]string{"type", request.Type},
		[2]string{"status", request.Status},
		[2]string{"managed_by", "kb-gateway"},
		[2]string{"created", created},
		[2]string{"updated", updated},
	)
	for _, field := range fields {
		fmt.Fprintf(&output, "%s: %s\n", field[0], strconv.Quote(field[1]))
	}
	if len(request.Source) > 0 {
		keys := make([]string, 0, len(request.Source))
		for key := range request.Source {
			keys = append(keys, key)
		}
		sort.Strings(keys)
		output.WriteString("source:\n")
		for _, key := range keys {
			fmt.Fprintf(&output, "  %s: %s\n", key, strconv.Quote(request.Source[key]))
		}
	}
	for _, line := range extra {
		output.WriteString(line)
		output.WriteByte('\n')
	}
	output.WriteString("---\n")
	return output.String()
}

func renderManagedBody(body string) string {
	return managedStart + "\n\n" + strings.TrimSpace(body) + "\n\n" + managedEnd
}

func splitFrontmatter(content string) (string, string, error) {
	if !strings.HasPrefix(content, "---\n") {
		return "", "", errors.New("missing frontmatter")
	}
	end := strings.Index(content[4:], "\n---\n")
	if end < 0 {
		return "", "", errors.New("invalid frontmatter")
	}
	end += 4
	return content[4:end], content[end+5:], nil
}

func frontmatterValue(header, key string) string {
	for _, line := range strings.Split(header, "\n") {
		if strings.HasPrefix(line, key+":") {
			return yamlValue(strings.TrimSpace(strings.TrimPrefix(line, key+":")))
		}
	}
	return ""
}

func yamlValue(raw string) string {
	if value, err := strconv.Unquote(raw); err == nil {
		return value
	}
	return raw
}

func unmanagedFrontmatter(header string) []string {
	managed := map[string]bool{
		"kb_id": true, "title": true, "profile": true, "domain": true,
		"project": true, "language": true, "type": true, "status": true,
		"managed_by": true, "created": true, "updated": true, "source": true,
	}
	lines := strings.Split(header, "\n")
	kept := make([]string, 0, len(lines))
	skip := false
	for _, line := range lines {
		if line != "" && line[0] != ' ' && line[0] != '\t' {
			key, _, found := strings.Cut(line, ":")
			skip = found && managed[strings.TrimSpace(key)]
		}
		if !skip && line != "" {
			kept = append(kept, line)
		}
	}
	return kept
}

func validateSource(source map[string]string) error {
	for key, value := range source {
		if safeSlug(key) != key || strings.ContainsAny(value, "\r\n") || filepath.IsAbs(value) {
			return errors.New("invalid source metadata")
		}
	}
	return nil
}

func ValidateFragment(value, name string) error {
	if strings.TrimSpace(value) == "" || strings.ContainsAny(value, "/\\\x00") || value == "." || value == ".." || safeSlug(value) == "" {
		return fmt.Errorf("invalid %s", name)
	}
	return nil
}

func safeSlug(value string) string {
	var output strings.Builder
	dash := false
	for _, character := range strings.ToLower(strings.TrimSpace(value)) {
		if unicode.IsLetter(character) || unicode.IsDigit(character) {
			output.WriteRune(character)
			dash = false
		} else if !dash && output.Len() > 0 {
			output.WriteByte('-')
			dash = true
		}
	}
	return strings.Trim(output.String(), "-")
}

func secureDir(root string, routes ...string) (string, error) {
	resolvedRoot, err := filepath.EvalSymlinks(root)
	if err != nil {
		return "", errors.New("resolve vault failed")
	}
	current := resolvedRoot
	for _, route := range routes {
		if strings.TrimSpace(route) == "" || filepath.IsAbs(route) {
			return "", errors.New("absolute routing path is forbidden")
		}
		for _, part := range strings.FieldsFunc(route, func(r rune) bool { return r == '/' || r == '\\' }) {
			if part == "" || part == "." || part == ".." {
				return "", errors.New("invalid routing path")
			}
			current = filepath.Join(current, part)
			info, err := os.Lstat(current)
			if os.IsNotExist(err) {
				if err := os.Mkdir(current, 0o755); err != nil {
					return "", errors.New("create route failed")
				}
				continue
			}
			if err != nil {
				return "", errors.New("inspect route failed")
			}
			if !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
				return "", errors.New("routing path contains a symlink or non-directory")
			}
		}
	}
	relative, err := filepath.Rel(resolvedRoot, current)
	if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return "", errors.New("routing escaped the vault")
	}
	return current, nil
}

func atomicWrite(path string, content []byte, mode os.FileMode, overwrite bool) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	temporary, err := os.CreateTemp(dir, ".kb-tmp-*")
	if err != nil {
		return err
	}
	temporaryPath := temporary.Name()
	defer os.Remove(temporaryPath)
	if err := temporary.Chmod(mode); err != nil {
		temporary.Close()
		return err
	}
	if _, err := temporary.Write(content); err != nil {
		temporary.Close()
		return err
	}
	if err := temporary.Sync(); err != nil {
		temporary.Close()
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	if overwrite {
		err = os.Rename(temporaryPath, path)
	} else {
		err = os.Link(temporaryPath, path)
	}
	if err != nil {
		return err
	}
	if !overwrite {
		if err := os.Remove(temporaryPath); err != nil {
			return err
		}
	}
	if directory, openErr := os.Open(dir); openErr == nil {
		_ = directory.Sync()
		_ = directory.Close()
	}
	return nil
}
