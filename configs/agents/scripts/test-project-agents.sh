#!/usr/bin/env bash
set -euo pipefail

script="${1:-$(dirname "$0")/project-agents.sh}"
script="$(cd -P -- "$(dirname "$script")" && pwd)/$(basename "$script")"
test_dir="$(mktemp -d)"
mock_bin="$test_dir/bin"
log="$test_dir/herdr.log"
state="$test_dir/server-running"
root="$test_dir/My Payments API"
launch_dir="$root/nested directory"
real_git="$(command -v git)"
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$mock_bin" "$launch_dir"
root="$(cd -P -- "$root" && pwd)"
launch_dir="$(cd -P -- "$launch_dir" && pwd)"

cat > "$mock_bin/git" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == rev-parse ]]; then
    printf '%s\n' "$HERDR_TEST_ROOT"
else
    exec "$HERDR_TEST_REAL_GIT" "$@"
fi
EOF

for command in claude codex copilot; do
    cat > "$mock_bin/$command" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
done

cat > "$mock_bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$HERDR_TEST_LOG"

case "${1:-}" in
    status)
        if [[ -e "$HERDR_TEST_STATE" ]]; then
            printf '{"running":true}\n'
        else
            printf '{"running":false}\n'
        fi
        ;;
    server)
        touch "$HERDR_TEST_STATE"
        ;;
    api)
        if [[ "${HERDR_TEST_MODE:-create}" == reuse ]]; then
            jq -n --arg cwd "$HERDR_TEST_CWD" '{result:{snapshot:{workspaces:[{workspace_id:"w9",label:"agents:My Payments API"}],panes:[{workspace_id:"w9",pane_id:"w9:p1",cwd:$cwd,label:"Claude",agent:"claude"},{workspace_id:"w9",pane_id:"w9:p2",cwd:$cwd,label:"Codex",agent:"codex"},{workspace_id:"w9",pane_id:"w9:p3",cwd:$cwd,label:"Copilot",agent:"copilot"}],agents:[{workspace_id:"w9",name:"claude-my-payments-api",agent:"claude"},{workspace_id:"w9",name:"codex-my-payments-api",agent:"codex"},{workspace_id:"w9",name:"copilot-my-payments-api",agent:"copilot"}]}}}'
        elif [[ "${HERDR_TEST_MODE:-create}" == missing ]]; then
            jq -n --arg root "$HERDR_TEST_ROOT" '{result:{snapshot:{workspaces:[{workspace_id:"w9",label:"agents:My Payments API"}],panes:[{workspace_id:"w9",pane_id:"w9:p1",cwd:$root,label:"Claude"},{workspace_id:"w9",pane_id:"w9:p2",cwd:$root,label:"Codex"},{workspace_id:"w9",pane_id:"w9:p3",cwd:$root,label:"Copilot"}],agents:[]}}}'
        elif [[ "${HERDR_TEST_MODE:-create}" == collision ]]; then
            printf '{"result":{"snapshot":{"workspaces":[],"panes":[],"agents":[{"workspace_id":"other","name":"claude-my-payments-api"}]}}}\n'
        else
            printf '{"result":{"snapshot":{"workspaces":[],"panes":[],"agents":[]}}}\n'
        fi
        ;;
    workspace)
        if [[ "${2:-}" == create ]]; then
            printf '{"result":{"workspace":{"workspace_id":"w1"},"root_pane":{"pane_id":"w1:p1"}}}\n'
        else
            printf '{"result":{"type":"ok"}}\n'
        fi
        ;;
    pane)
        if [[ "${2:-}" == split && "$*" == *"--pane w1:p1"* ]]; then
            printf '{"result":{"pane":{"pane_id":"w1:p2"}}}\n'
        elif [[ "${2:-}" == split ]]; then
            printf '{"result":{"pane":{"pane_id":"w1:p3"}}}\n'
        else
            printf '{"result":{"type":"ok"}}\n'
        fi
        ;;
    agent)
        printf '{"result":{"type":"ok"}}\n'
        ;;
esac
EOF

chmod +x "$mock_bin"/*

run_launcher() (
    cd "$launch_dir"
    HERDR_TEST_ROOT="$root" \
    HERDR_TEST_CWD="$launch_dir" \
    HERDR_TEST_LOG="$log" \
    HERDR_TEST_STATE="$state" \
    HERDR_TEST_MODE="${1:-create}" \
    HERDR_TEST_REAL_GIT="$real_git" \
    PATH="$mock_bin:$PATH" \
        bash "$script" >/dev/null
)

run_launcher

grep -Fqx "workspace create --cwd $launch_dir --label agents:My Payments API --no-focus" "$log"
grep -Fqx "pane split --pane w1:p1 --direction right --ratio 0.5 --cwd $launch_dir --no-focus" "$log"
grep -Fqx "pane split --pane w1:p2 --direction down --ratio 0.5 --cwd $launch_dir --no-focus" "$log"
grep -Fqx "agent start claude-my-payments-api --kind claude --pane w1:p1 --timeout 4000" "$log"
grep -Fqx "agent start codex-my-payments-api --kind codex --pane w1:p2 --timeout 4000" "$log"
grep -Fqx "agent start copilot-my-payments-api --kind copilot --pane w1:p3 --timeout 4000" "$log"
grep -Fqx "workspace focus w1" "$log"
grep -Fqx "agent focus w1:p1" "$log"
test "$(grep -c '^pane split ' "$log")" -eq 2

: > "$log"
run_launcher reuse

grep -Fqx "workspace focus w9" "$log"
if grep -Eq '^(workspace create|pane split|agent start) ' "$log"; then
    echo "reuse mutated the existing workspace" >&2
    exit 1
fi

: > "$log"
HERDR_ENV=1 run_launcher reuse
if grep -qx '' "$log"; then
    echo "launcher tried to nest Herdr" >&2
    exit 1
fi

: > "$log"
run_launcher missing
if grep -Eq '^(workspace create|pane split) ' "$log"; then
    echo "repair recreated the existing workspace" >&2
    exit 1
fi
grep -Fqx "agent start claude-my-payments-api --kind claude --pane w9:p1 --timeout 4000" "$log"
grep -Fqx "agent start codex-my-payments-api --kind codex --pane w9:p2 --timeout 4000" "$log"
grep -Fqx "agent start copilot-my-payments-api --kind copilot --pane w9:p3 --timeout 4000" "$log"
printf -v quoted_launch_dir '%q' "$launch_dir"
grep -Fqx "pane run w9:p1 cd -- $quoted_launch_dir" "$log"
grep -Fqx "pane run w9:p2 cd -- $quoted_launch_dir" "$log"
grep -Fqx "pane run w9:p3 cd -- $quoted_launch_dir" "$log"

: > "$log"
run_launcher collision

hashed_slug="my-payments-api-$(printf '%s' "$root" | git hash-object --stdin | cut -c1-6)"
grep -Fqx "agent start claude-$hashed_slug --kind claude --pane w1:p1 --timeout 4000" "$log"
grep -Fqx "agent start codex-$hashed_slug --kind codex --pane w1:p2 --timeout 4000" "$log"
grep -Fqx "agent start copilot-$hashed_slug --kind copilot --pane w1:p3 --timeout 4000" "$log"

echo "project-agents test passed"
