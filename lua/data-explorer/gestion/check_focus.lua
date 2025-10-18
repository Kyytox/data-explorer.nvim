local state = require("data-explorer.gestion.state")
local actions = require("data-explorer.actions.actions_windows")

local M = {}

-- Clear Autocommands
local function clear_autocommands()
	vim.api.nvim_clear_autocmds({ group = "DataExplorerGroup" })
end

--- Check if the currently focused window is one of the main plugin windows.
---@param wins table: Table of window handles.
---@return boolean: True if a main window is focused, false otherwise.
local function is_plugin_window_focused(wins)
	local current_win = vim.api.nvim_get_current_win()

	-- Check against the window handles (win_meta, win_data, win_help)
	for key, win_id in pairs(wins) do
		-- Only check if it's an actual window handle (not a buffer handle)
		if type(win_id) == "number" and vim.api.nvim_win_is_valid(win_id) and current_win == win_id then
			return true
		end
	end

	return false
end

--- Checks focus and closes the main UI if focus is lost.
function M.check_focus_and_close()
	local wins = state.get_state("windows")
	if not wins or vim.tbl_isempty(wins) then
		return
	end

	-- If the currently active window is NOT one of our main windows, close them all.
	if not is_plugin_window_focused(wins) then
		actions.close_windows()
		clear_autocommands()
		state.reset_state()
	end
end

return M
