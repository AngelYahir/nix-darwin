package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"os"
	"path/filepath"
	"time"

	"kb-gateway/internal/kb"
)

func main() {
	if err := run(os.Args[1:], os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "kb:", err)
		os.Exit(1)
	}
}

func run(args []string, stdout io.Writer) error {
	if len(args) == 0 {
		return errors.New("usage: kb init|register|unregister|status")
	}
	paths, err := kb.DefaultPaths()
	if err != nil {
		return err
	}
	switch args[0] {
	case "init":
		flags := quietFlags("kb init")
		var name, vault string
		flags.StringVar(&name, "name", "", "vault alias")
		flags.StringVar(&vault, "vault", "", "Obsidian vault path")
		if err := flags.Parse(args[1:]); err != nil || flags.NArg() != 0 || vault == "" {
			return errors.New("usage: kb init [--name ALIAS] --vault PATH")
		}
		var err error
		if name == "" {
			err = kb.WriteVaultRoot(paths.Local, vault)
		} else {
			err = kb.RegisterVault(paths.Local, name, vault)
		}
		if err != nil {
			return err
		}
		fmt.Fprintln(stdout, "vault configured")
		return nil

	case "register":
		flags := quietFlags("kb register")
		var domain, project string
		flags.StringVar(&domain, "domain", "", "knowledge domain")
		flags.StringVar(&project, "project", "", "project name")
		if err := flags.Parse(args[1:]); err != nil || flags.NArg() != 0 || project == "" {
			return errors.New("usage: kb register --domain work1|work2|personal --project NAME")
		}
		policy, err := kb.LoadPolicy(paths.Policy)
		if err != nil {
			return err
		}
		if domain == "languages" || policy.DomainRoutes[domain] == "" {
			return errors.New("project domain must be work1, work2, or personal")
		}
		if err := kb.ValidateFragment(project, "project"); err != nil {
			return err
		}
		root, err := kb.RepositoryRoot(".")
		if err != nil {
			return err
		}
		if err := kb.RegisterProject(paths.Projects, root, domain, project); err != nil {
			return err
		}
		fmt.Fprintf(stdout, "registered: %s (%s)\n", project, domain)
		return nil

	case "unregister":
		if len(args) != 1 {
			return errors.New("usage: kb unregister")
		}
		root, err := kb.RepositoryRoot(".")
		if err != nil {
			return err
		}
		found, err := kb.UnregisterProject(paths.Projects, root)
		if err != nil {
			return err
		}
		if !found {
			return errors.New("current project is not registered")
		}
		fmt.Fprintln(stdout, "project unregistered")
		return nil

	case "status":
		if len(args) != 1 {
			return errors.New("usage: kb status")
		}
		if _, err := kb.LoadVaultRoot(paths.Local); err != nil {
			fmt.Fprintln(stdout, "vault: unavailable")
		} else {
			fmt.Fprintln(stdout, "vault: ok")
		}
		connection, err := net.DialTimeout("unix", paths.Socket, 300*time.Millisecond)
		if err != nil {
			fmt.Fprintln(stdout, "gateway: unavailable")
		} else {
			connection.Close()
			fmt.Fprintln(stdout, "gateway: ok")
		}
		root, rootErr := kb.RepositoryRoot(".")
		projects, projectsErr := kb.LoadProjects(paths.Projects)
		if rootErr == nil && projectsErr == nil {
			if project, found := kb.FindProject(projects, filepath.Clean(root)); found {
				fmt.Fprintf(stdout, "project: %s (%s)\n", project.Project, project.Domain)
				return nil
			}
		}
		fmt.Fprintln(stdout, "project: unregistered")
		return nil

	default:
		return errors.New("usage: kb init|register|unregister|status")
	}
}

func quietFlags(name string) *flag.FlagSet {
	flags := flag.NewFlagSet(name, flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	return flags
}
