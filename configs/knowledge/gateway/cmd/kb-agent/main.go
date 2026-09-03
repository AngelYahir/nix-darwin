package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"

	"kb-gateway/internal/kb"
)

func main() {
	if err := run(os.Args[1:], os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "kb-agent:", err)
		os.Exit(1)
	}
}

func run(args []string, stdin io.Reader, stdout io.Writer) error {
	if len(args) == 0 || args[0] != "upsert" {
		return errors.New("usage: kb-agent upsert [options]")
	}
	flags := flag.NewFlagSet("kb-agent upsert", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	var request kb.Request
	var file, sourceRepo, sourceTask, sourceCommit string
	var projectAuto bool
	flags.StringVar(&request.Profile, "profile", "engineering", "publication profile")
	flags.StringVar(&request.KBID, "id", "", "stable knowledge id")
	flags.StringVar(&request.Title, "title", "", "note title")
	flags.StringVar(&request.Domain, "domain", "", "knowledge domain")
	flags.StringVar(&request.Project, "project", "", "project name")
	flags.StringVar(&request.Language, "language", "", "language name")
	flags.StringVar(&request.Type, "type", "", "knowledge type")
	flags.StringVar(&request.Status, "status", "canonical", "note status")
	flags.StringVar(&file, "file", "", "read body from file instead of stdin")
	flags.BoolVar(&projectAuto, "project-auto", false, "resolve domain and project from the local registry")
	flags.StringVar(&sourceRepo, "source-repo", "", "non-local repository reference")
	flags.StringVar(&sourceTask, "source-task", "", "task reference")
	flags.StringVar(&sourceCommit, "source-commit", "", "commit reference")
	if err := flags.Parse(args[1:]); err != nil || flags.NArg() != 0 {
		return errors.New("invalid upsert options")
	}

	paths, err := kb.DefaultPaths()
	if err != nil {
		return err
	}
	if projectAuto {
		root, err := kb.RepositoryRoot(".")
		if err != nil {
			return err
		}
		projects, err := kb.LoadProjects(paths.Projects)
		if err != nil {
			return fmt.Errorf("project registry: %w", err)
		}
		project, found := kb.FindProject(projects, root)
		if !found {
			return errors.New("unknown project; run kb register first")
		}
		request.ProjectKey = kb.RepositoryKey(root)
		request.Domain = project.Domain
		request.Project = project.Project
	} else if request.Profile == "engineering" {
		return errors.New("engineering publication requires --project-auto")
	}

	var body []byte
	if file != "" {
		body, err = os.ReadFile(file)
	} else {
		body, err = io.ReadAll(io.LimitReader(stdin, 4<<20+1))
	}
	if err != nil {
		return fmt.Errorf("read note body: %w", err)
	}
	if len(body) > 4<<20 {
		return errors.New("note body is too large")
	}
	request.Operation = "upsert"
	request.Body = string(body)
	request.Source = map[string]string{}
	for key, value := range map[string]string{"repo": sourceRepo, "task": sourceTask, "commit": sourceCommit} {
		if value != "" {
			request.Source[key] = value
		}
	}
	if len(request.Source) == 0 {
		request.Source = nil
	}

	response, err := kb.Send(paths.Socket, request)
	if err != nil {
		return err
	}
	_, err = fmt.Fprintf(stdout, "%s: %s\n", response.Result, response.KBID)
	return err
}
