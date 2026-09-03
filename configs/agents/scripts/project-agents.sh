set -euo pipefail

for dependency in herdr git jq claude codex copilot; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        echo "error: missing command: $dependency" >&2
        exit 1
    fi
done

if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    root="$(cd -P -- "$git_root" && pwd)"
else
    root="$(pwd -P)"
    echo "warning: no Git repository detected; using current directory" >&2
fi
launch_dir="$(pwd -P)"

project_name="$(basename -- "$root")"
slug="$(printf '%s' "$project_name" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-24)"
slug="${slug:-project}"

workspace_label="agents:$project_name"

echo "Project: $root"
echo "Directory: $launch_dir"
echo "Workspace: $workspace_label"

server_running() {
    local status
    status="$(herdr status server --json 2>/dev/null)" \
        && jq -e '.running == true' >/dev/null <<<"$status"
}

start_agent() {
    local label="$1" name="$2" kind="$3" pane="$4" error

    if error="$(herdr agent start "$name" --kind "$kind" --pane "$pane" --timeout 4000 2>&1)"; then
        return
    fi
    if herdr agent get "$name" 2>/dev/null \
        | jq -e --arg kind "$kind" '.result.agent.agent == $kind' >/dev/null; then
        return
    fi

    echo "warning: $label could not start automatically" >&2
    printf '%s\n' "$error" >&2
}

ensure_agent() {
    local label="$1" name="$2" kind="$3" pane="$4" pane_cwd command

    if [[ -z "$pane" ]]; then
        echo "warning: $label pane is missing" >&2
        return
    fi
    if jq -e --arg pane "$pane" --arg kind "$kind" '
        any(.result.snapshot.panes[]; .pane_id == $pane and .agent == $kind)
    ' <<<"$snapshot" >/dev/null; then
        return
    fi

    pane_cwd="$(jq -r --arg pane "$pane" '[.result.snapshot.panes[] | select(.pane_id == $pane) | (.foreground_cwd // .cwd)][0] // ""' <<<"$snapshot")"
    if [[ "$pane_cwd" != "$launch_dir" ]]; then
        printf -v command 'cd -- %q' "$launch_dir"
        if ! herdr pane run "$pane" "$command" >/dev/null; then
            echo "warning: $label pane could not enter $launch_dir" >&2
            return
        fi
    fi

    start_agent "$label" "$name" "$kind" "$pane"
}

if ! server_running; then
    nohup env -u HERDR_STARTUP_CWD herdr server >/dev/null 2>&1 &

    for _ in $(seq 1 100); do
        if server_running; then
            break
        fi
        sleep 0.1
    done

    if ! server_running; then
        echo "error: Herdr server did not become available" >&2
        exit 1
    fi
fi

snapshot="$(herdr api snapshot)"
workspace_id="$(jq -r --arg root "$root" --arg label "$workspace_label" '
    def within($root):
        . == $root or ($root != "/" and startswith($root + "/"));
    .result.snapshot as $snapshot
    | [
        $snapshot.workspaces[]
        | select(.label == $label)
        | . as $workspace
        | select(any(
            $snapshot.panes[];
            .workspace_id == $workspace.workspace_id
            and (
                ((.cwd // "") | within($root))
                or ((.foreground_cwd // "") | within($root))
            )
        ))
        | .workspace_id
      ][0] // ""
' <<<"$snapshot")"

if jq -e --arg slug "$slug" --arg workspace_id "$workspace_id" '
        any(
            .result.snapshot.agents[];
            .workspace_id != $workspace_id
            and (
                .name == "claude-\($slug)"
                or .name == "codex-\($slug)"
                or .name == "copilot-\($slug)"
            )
        )
    ' <<<"$snapshot" >/dev/null; then
    slug="${slug:0:17}-$(printf '%s' "$root" | git hash-object --stdin | cut -c1-6)"
fi

claude_name="claude-$slug"
codex_name="codex-$slug"
copilot_name="copilot-$slug"

if [[ -n "$workspace_id" ]]; then
    echo "Reusing existing Herdr workspace for project..."
    claude_pane="$(jq -r --arg workspace_id "$workspace_id" '[.result.snapshot.panes[] | select(.workspace_id == $workspace_id and .label == "Claude") | .pane_id][0] // ""' <<<"$snapshot")"
    codex_pane="$(jq -r --arg workspace_id "$workspace_id" '[.result.snapshot.panes[] | select(.workspace_id == $workspace_id and .label == "Codex") | .pane_id][0] // ""' <<<"$snapshot")"
    copilot_pane="$(jq -r --arg workspace_id "$workspace_id" '[.result.snapshot.panes[] | select(.workspace_id == $workspace_id and .label == "Copilot") | .pane_id][0] // ""' <<<"$snapshot")"
else
    echo "Claude: $claude_name"
    echo "Codex: $codex_name"
    echo "Copilot: $copilot_name"

    created="$(herdr workspace create --cwd "$launch_dir" --label "$workspace_label" --no-focus)"
    workspace_id="$(jq -er '.result.workspace.workspace_id' <<<"$created")"
    claude_pane="$(jq -er '.result.root_pane.pane_id' <<<"$created")"

    codex_pane="$(herdr pane split --pane "$claude_pane" --direction right --ratio 0.5 --cwd "$launch_dir" --no-focus \
        | jq -er '.result.pane.pane_id')"
    copilot_pane="$(herdr pane split --pane "$codex_pane" --direction down --ratio 0.5 --cwd "$launch_dir" --no-focus \
        | jq -er '.result.pane.pane_id')"

    herdr pane rename "$claude_pane" Claude >/dev/null
    herdr pane rename "$codex_pane" Codex >/dev/null
    herdr pane rename "$copilot_pane" Copilot >/dev/null
fi

herdr workspace focus "$workspace_id" >/dev/null

ensure_agent Claude "$claude_name" claude "$claude_pane" &
claude_start_pid=$!
ensure_agent Codex "$codex_name" codex "$codex_pane" &
codex_start_pid=$!
ensure_agent Copilot "$copilot_name" copilot "$copilot_pane" &
copilot_start_pid=$!
wait "$claude_start_pid" "$codex_start_pid" "$copilot_start_pid"

herdr workspace focus "$workspace_id" >/dev/null
if [[ -n "$claude_pane" ]] && ! herdr agent focus "$claude_pane" >/dev/null 2>&1; then
    echo "warning: Claude pane is unavailable for focus" >&2
fi

if [[ "${HERDR_ENV:-}" != 1 ]]; then
    exec herdr
fi
