local M = {}

M.events = { "aerospace_workspace_change", "front_app_switched" }

function M.fetch_state_cmd()
	return "aerospace list-windows --all --format '%{workspace}|%{app-name}'"
		.. " && echo '---' && aerospace list-workspaces --all"
		.. " && echo '---' && aerospace list-workspaces --focused"
end

function M.click_cmd(workspace_id)
	return 'aerospace workspace "' .. workspace_id .. '"'
end

function M.display_label(workspace_id)
	return workspace_id
end

return M
