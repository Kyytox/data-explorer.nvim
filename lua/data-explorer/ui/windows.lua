local M = {}

--- Create a floating window with the given options.
---@param opts table: Window dimensions and position.
---@return number, number: Buffer and window handles.
function M.create_floating_window(opts)
	opts = opts or {}

	local width = opts.width or math.floor(vim.o.columns * 0.7)
	local height = opts.height or math.floor(vim.o.lines * 0.6)
	local buf = vim.api.nvim_create_buf(false, true)

	local win = vim.api.nvim_open_win(buf, true, {
		title = opts.title,
		title_pos = opts.title_pos or "right",
		relative = "editor",
		width = width,
		height = height,
		row = opts.row or math.floor((vim.o.lines - height) / 2),
		col = opts.col or math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		focusable = opts.focusable or true,
		hide = opts.hide or false,
		footer = opts.footer or "",
		footer_pos = "right",
	})
	return buf, win
end

--- Close all open windows.
---@param wins table: Table of window handles.
function M.close_windows(wins)
	for _, win in ipairs(wins) do
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
end

--- Focus on a specific window.
---@param win table: Window handle.
function M.focus_window(win)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
	end
end

-- Toggle window visibility (hide)
function M.toggle_hdie_window(win)
	if vim.api.nvim_win_is_valid(win) then
		local is_visible = vim.api.nvim_win_get_config(win).hide

		vim.api.nvim_win_set_config(win, { hide = not is_visible })
		if is_visible then
			M.focus_window(win)
			vim.cmd("startinsert") -- Activate insert mode
			vim.api.nvim_win_set_cursor(win, { 2, 0 })
			return is_visible
		end
	end
end

return M
