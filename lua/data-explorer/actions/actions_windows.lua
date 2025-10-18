local state = require("data-explorer.gestion.state")

local M = {}

--- Close all open windows.
function M.close_windows()
	local wins = state.get_state("windows")

	for key, win in pairs(wins) do
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	-- Remove the window from state
	-- state.reset_state("windows")
end

-- Focus on a specific buffer.
---@param buf integer: Buffer handle.
function M.focus_buffer(buf)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_set_current_buf(buf)
	end
end

-- Focus on a specific window.
---@param win integer: Window handle.
function M.focus_window(win)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
	end
end

-- Toggle window visibility and focus on appropriate window.
---@param win integer: Window handle.
---@param win_visible integer|nil: Window to focus on if the target window is made visible.
---@param win_hidden integer|nil: Window to focus on if the target window is hidden.
function M.toggle_window_focus(win, win_visible, win_hidden)
	if vim.api.nvim_win_is_valid(win) then
		local is_visible = vim.api.nvim_win_get_config(win).hide

		vim.api.nvim_win_set_config(win, { hide = not is_visible })

		-- Focus on appropriate window
		if is_visible and win_visible then
			M.focus_window(win_visible)
		elseif not is_visible and win_hidden then
			M.focus_window(win_hidden)
		end
	end
end

return M
