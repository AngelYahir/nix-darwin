package kb

import (
	"bufio"
	"crypto/sha256"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

type Profile struct {
	AllowedDomains map[string]bool
	AllowedTypes   map[string]bool
	Route          string
}

type Policy struct {
	Profiles       map[string]Profile
	DomainRoutes   map[string]string
	TypeRoutes     map[string]string
	ProjectsFolder string
}

type Project struct {
	Repo    string
	Domain  string
	Project string
}

func LoadPolicy(path string) (Policy, error) {
	sections, err := parseSections(path)
	if err != nil {
		return Policy{}, fmt.Errorf("policy: %w", err)
	}
	policy := Policy{
		Profiles:       map[string]Profile{},
		DomainRoutes:   map[string]string{},
		TypeRoutes:     map[string]string{},
		ProjectsFolder: "Projects",
	}
	for section, values := range sections {
		switch {
		case strings.HasPrefix(section, "profiles."):
			name := strings.TrimPrefix(section, "profiles.")
			domains, err := parseStringArray(values["allowed_domains"])
			if err != nil {
				return Policy{}, fmt.Errorf("profile %s allowed_domains: %w", name, err)
			}
			types, err := parseStringArray(values["allowed_types"])
			if err != nil {
				return Policy{}, fmt.Errorf("profile %s allowed_types: %w", name, err)
			}
			route, err := parseString(values["route"])
			if err != nil || (route != "project" && route != "personal") {
				return Policy{}, fmt.Errorf("profile %s has invalid route", name)
			}
			policy.Profiles[name] = Profile{set(domains), set(types), route}
		case section == "routing.domains":
			if err := parseStringMap(values, policy.DomainRoutes); err != nil {
				return Policy{}, fmt.Errorf("domain routing: %w", err)
			}
		case section == "routing.types":
			if err := parseStringMap(values, policy.TypeRoutes); err != nil {
				return Policy{}, fmt.Errorf("type routing: %w", err)
			}
		case section == "routing" && values["projects"] != "":
			policy.ProjectsFolder, err = parseString(values["projects"])
			if err != nil {
				return Policy{}, fmt.Errorf("projects route: %w", err)
			}
		}
	}
	if len(policy.Profiles) == 0 || len(policy.DomainRoutes) == 0 || len(policy.TypeRoutes) == 0 {
		return Policy{}, errors.New("missing profiles or routing")
	}
	return policy, nil
}

func LoadVaultRoot(path string) (string, error) {
	return LoadVault(path, "")
}

func LoadVault(path, name string) (string, error) {
	sections, err := parseSections(path)
	if err != nil {
		if os.IsNotExist(err) {
			return "", fmt.Errorf("missing local config; run kb init --vault PATH")
		}
		return "", fmt.Errorf("local config: %w", err)
	}
	raw := sections[""]["vault_root"]
	if name != "" {
		if safeSlug(name) != name {
			return "", errors.New("invalid vault alias")
		}
		raw = sections["vaults"][name]
		if raw == "" {
			return "", errors.New("unknown vault alias")
		}
	}
	root, err := parseString(raw)
	if err != nil || !filepath.IsAbs(root) {
		return "", errors.New("local config: vault_root must be an absolute path")
	}
	root, err = filepath.EvalSymlinks(root)
	if err != nil {
		return "", errors.New("local config: cannot resolve vault_root")
	}
	info, err := os.Stat(root)
	if err != nil || !info.IsDir() {
		return "", errors.New("local config: vault_root is not a directory")
	}
	return root, nil
}

func WriteVaultRoot(path, root string) error {
	return writeVault(path, "", root)
}

func RegisterVault(path, name, root string) error {
	if name == "" || safeSlug(name) != name {
		return errors.New("vault name must be a lowercase alias")
	}
	return writeVault(path, name, root)
}

func writeVault(path, name, root string) error {
	abs, err := filepath.Abs(root)
	if err != nil {
		return fmt.Errorf("resolve vault path: %w", err)
	}
	abs, err = filepath.EvalSymlinks(abs)
	if err != nil {
		return fmt.Errorf("resolve vault path: %w", err)
	}
	info, err := os.Stat(abs)
	if err != nil || !info.IsDir() {
		return errors.New("vault must be an existing directory")
	}

	defaultRoot := abs
	vaults := map[string]string{}
	sections, err := parseSections(path)
	if err == nil {
		if name != "" {
			defaultRoot, err = parseString(sections[""]["vault_root"])
			if err != nil || !filepath.IsAbs(defaultRoot) {
				return errors.New("local config: vault_root must be an absolute path")
			}
		}
		if err := parseStringMap(sections["vaults"], vaults); err != nil {
			return fmt.Errorf("local config vaults: %w", err)
		}
	} else if !os.IsNotExist(err) {
		return fmt.Errorf("local config: %w", err)
	}
	if name != "" {
		vaults[name] = abs
	}

	var output strings.Builder
	fmt.Fprintf(&output, "vault_root = %s\n", strconv.Quote(defaultRoot))
	if len(vaults) > 0 {
		output.WriteString("\n[vaults]\n")
		names := make([]string, 0, len(vaults))
		for name := range vaults {
			names = append(names, name)
		}
		sort.Strings(names)
		for _, name := range names {
			fmt.Fprintf(&output, "%s = %s\n", name, strconv.Quote(vaults[name]))
		}
	}
	return atomicWrite(path, []byte(output.String()), 0o600, true)
}

func LoadProjects(path string) ([]Project, error) {
	file, err := os.Open(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	defer file.Close()

	var projects []Project
	var current *Project
	scanner := bufio.NewScanner(file)
	for lineNumber := 1; scanner.Scan(); lineNumber++ {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if line == "[[projects]]" {
			projects = append(projects, Project{})
			current = &projects[len(projects)-1]
			continue
		}
		if current == nil {
			return nil, fmt.Errorf("line %d: expected [[projects]]", lineNumber)
		}
		key, raw, ok := strings.Cut(line, "=")
		if !ok {
			return nil, fmt.Errorf("line %d: invalid assignment", lineNumber)
		}
		value, err := parseString(strings.TrimSpace(raw))
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", lineNumber, err)
		}
		switch strings.TrimSpace(key) {
		case "repo":
			current.Repo = value
		case "domain":
			current.Domain = value
		case "project":
			current.Project = value
		default:
			return nil, fmt.Errorf("line %d: unknown key", lineNumber)
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	for _, project := range projects {
		if !filepath.IsAbs(project.Repo) || project.Domain == "" || project.Project == "" {
			return nil, errors.New("registry contains an incomplete project")
		}
	}
	seen := map[string]bool{}
	for _, project := range projects {
		if seen[project.Repo] {
			return nil, errors.New("registry contains a duplicate repository")
		}
		seen[project.Repo] = true
	}
	return projects, nil
}

func WriteProjects(path string, projects []Project) error {
	sort.Slice(projects, func(i, j int) bool { return projects[i].Repo < projects[j].Repo })
	var output strings.Builder
	for _, project := range projects {
		output.WriteString("[[projects]]\nrepo = ")
		output.WriteString(strconv.Quote(project.Repo))
		output.WriteString("\ndomain = ")
		output.WriteString(strconv.Quote(project.Domain))
		output.WriteString("\nproject = ")
		output.WriteString(strconv.Quote(project.Project))
		output.WriteString("\n\n")
	}
	return atomicWrite(path, []byte(output.String()), 0o600, true)
}

func RegisterProject(path, repo, domain, name string) error {
	projects, err := LoadProjects(path)
	if err != nil {
		return err
	}
	for i := range projects {
		if projects[i].Repo == repo {
			projects[i].Domain = domain
			projects[i].Project = name
			return WriteProjects(path, projects)
		}
	}
	return WriteProjects(path, append(projects, Project{Repo: repo, Domain: domain, Project: name}))
}

func UnregisterProject(path, repo string) (bool, error) {
	projects, err := LoadProjects(path)
	if err != nil {
		return false, err
	}
	filtered := projects[:0]
	found := false
	for _, project := range projects {
		if project.Repo == repo {
			found = true
			continue
		}
		filtered = append(filtered, project)
	}
	if !found {
		return false, nil
	}
	return true, WriteProjects(path, filtered)
}

func FindProject(projects []Project, repo string) (Project, bool) {
	for _, project := range projects {
		if project.Repo == repo {
			return project, true
		}
	}
	return Project{}, false
}

func FindProjectByKey(projects []Project, key string) (Project, bool) {
	for _, project := range projects {
		if RepositoryKey(project.Repo) == key {
			return project, true
		}
	}
	return Project{}, false
}

func RepositoryKey(repo string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(filepath.Clean(repo))))
}

func RepositoryRoot(dir string) (string, error) {
	command := exec.Command("git", "-C", dir, "rev-parse", "--show-toplevel")
	output, err := command.Output()
	if err != nil {
		return "", errors.New("current directory is not inside a Git repository")
	}
	root := strings.TrimSpace(string(output))
	root, err = filepath.EvalSymlinks(root)
	if err != nil {
		return "", fmt.Errorf("resolve repository root: %w", err)
	}
	return filepath.Clean(root), nil
}

func parseSections(path string) (map[string]map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	sections := map[string]map[string]string{"": {}}
	section := ""
	scanner := bufio.NewScanner(file)
	for lineNumber := 1; scanner.Scan(); lineNumber++ {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			section = strings.TrimSpace(line[1 : len(line)-1])
			if section == "" {
				return nil, fmt.Errorf("line %d: empty section", lineNumber)
			}
			if sections[section] == nil {
				sections[section] = map[string]string{}
			}
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok || strings.TrimSpace(key) == "" {
			return nil, fmt.Errorf("line %d: invalid assignment", lineNumber)
		}
		sections[section][strings.TrimSpace(key)] = strings.TrimSpace(value)
	}
	return sections, scanner.Err()
}

func parseString(raw string) (string, error) {
	if raw == "" {
		return "", errors.New("missing string")
	}
	value, err := strconv.Unquote(raw)
	if err != nil {
		return "", errors.New("expected quoted string")
	}
	return value, nil
}

func parseStringArray(raw string) ([]string, error) {
	raw = strings.TrimSpace(raw)
	if len(raw) < 2 || raw[0] != '[' || raw[len(raw)-1] != ']' {
		return nil, errors.New("expected string array")
	}
	raw = strings.TrimSpace(raw[1 : len(raw)-1])
	if raw == "" {
		return nil, nil
	}
	parts := strings.Split(raw, ",")
	values := make([]string, 0, len(parts))
	for _, part := range parts {
		value, err := parseString(strings.TrimSpace(part))
		if err != nil {
			return nil, err
		}
		values = append(values, value)
	}
	return values, nil
}

func parseStringMap(input, output map[string]string) error {
	for key, raw := range input {
		value, err := parseString(raw)
		if err != nil {
			return fmt.Errorf("%s: %w", key, err)
		}
		output[key] = value
	}
	return nil
}

func set(values []string) map[string]bool {
	result := make(map[string]bool, len(values))
	for _, value := range values {
		result[value] = true
	}
	return result
}
