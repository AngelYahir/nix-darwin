package kb

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"path/filepath"
	"time"
)

const maxRequestBytes = 8 << 20

type Request struct {
	Operation  string            `json:"operation"`
	Vault      string            `json:"vault,omitempty"`
	Profile    string            `json:"profile"`
	KBID       string            `json:"kb_id"`
	Title      string            `json:"title"`
	Domain     string            `json:"domain"`
	Project    string            `json:"project,omitempty"`
	Language   string            `json:"language,omitempty"`
	Type       string            `json:"type"`
	Status     string            `json:"status,omitempty"`
	Body       string            `json:"body"`
	ProjectKey string            `json:"project_key,omitempty"`
	Source     map[string]string `json:"source,omitempty"`
}

type Response struct {
	OK     bool   `json:"ok"`
	Result string `json:"result,omitempty"`
	KBID   string `json:"kb_id,omitempty"`
	Error  string `json:"error,omitempty"`
}

type Paths struct {
	ConfigDir string
	Policy    string
	Local     string
	Projects  string
	StateDir  string
	Socket    string
}

func DefaultPaths() (Paths, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return Paths{}, fmt.Errorf("find home directory: %w", err)
	}
	configDir := filepath.Join(home, ".config", "kb")
	stateDir := filepath.Join(home, "Library", "Application Support", "kb-gateway")
	return Paths{
		ConfigDir: configDir,
		Policy:    filepath.Join(configDir, "policy.toml"),
		Local:     filepath.Join(configDir, "local.toml"),
		Projects:  filepath.Join(configDir, "projects.toml"),
		StateDir:  stateDir,
		Socket:    filepath.Join(stateDir, "gateway.sock"),
	}, nil
}

func Send(socket string, request Request) (Response, error) {
	conn, err := net.DialTimeout("unix", socket, 3*time.Second)
	if err != nil {
		return Response{}, fmt.Errorf("connect to kb-gateway: %w", err)
	}
	defer conn.Close()

	if err := json.NewEncoder(conn).Encode(request); err != nil {
		return Response{}, fmt.Errorf("send request: %w", err)
	}
	if unix, ok := conn.(*net.UnixConn); ok {
		_ = unix.CloseWrite()
	}

	var response Response
	if err := json.NewDecoder(bufio.NewReader(io.LimitReader(conn, 1<<20))).Decode(&response); err != nil {
		return Response{}, fmt.Errorf("read response: %w", err)
	}
	if !response.OK {
		if response.Error == "" {
			return Response{}, errors.New("kb-gateway rejected the request")
		}
		return Response{}, errors.New(response.Error)
	}
	return response, nil
}
