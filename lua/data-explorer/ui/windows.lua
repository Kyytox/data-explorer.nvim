local config_windows = require("data-explorer.ui.config_windows")
local state = require("data-explorer.state")
local actions_windows = require("data-explorer.actions.actions_windows")

local M = {}

--- Create a floating window with the given options.
---@param buffer number: Buffer handle.
---@param wins_infos table: Window layout parameters (width, height, row, col, title, etc.).
---@param opts table: Options table (for border style, etc.).
---@return number: Buffer and window handles.
local function create_floating_window(buffer, wins_infos, opts)
	local conf = {
		title = wins_infos.title,
		title_pos = wins_infos.title_pos,
		relative = "editor",
		width = wins_infos.width,
		height = wins_infos.height,
		row = wins_infos.row,
		col = wins_infos.col,
		style = "minimal",
		border = opts.window_opts.border,
		focusable = wins_infos.focusable or true,
		hide = wins_infos.hide or false,
		footer = wins_infos.footer or "",
		footer_pos = "left",
	}

	-- Create the floating window
	local win = vim.api.nvim_open_win(buffer, true, conf)

	return win
end

--- Create Metadata and Data windows based on layout
---@param dims table: Calculated dimensions for windows.
---@param opts table: Options table.
function M.create_windows(opts, dims)
	-- Clean up old windows
	actions_windows.close_windows()
	vim.notify("dims: " .. vim.inspect(dims))

	-- Get windows infos
	local wins_infos = state.get_variable("windows_infos")

	-- Retrieve buffers from state
	local buffers = state.get_state("buffers")

	-- Create help window
	local win_help = create_floating_window(buffers.buf_help, {
		title = wins_infos.help_title,
		width = dims.main_width,
		height = dims.help_height,
		row = 1,
		col = dims.col_start,
	}, opts)

	-- Create SQL windows
	local win_sql = create_floating_window(buffers.buf_sql, {
		title = wins_infos.sql_title,
		title_pos = "left",
		width = dims.main_width,
		height = dims.sql_height,
		row = dims.sql_row_start,
		col = dims.col_start,
		hide = true,
	}, opts)

	local win_sql_err = create_floating_window(buffers.buf_sql_err, {
		title = wins_infos.sql_err_title,
		title_pos = "left",
		width = dims.main_width,
		height = dims.sql_err_height,
		row = dims.sql_err_row_start,
		col = dims.col_start,
		hide = true,
	}, opts)

	vim.notify(
		"meta width: "
			.. dims.meta_width
			.. ", meta_height: "
			.. dims.meta_height
			.. ", row_start: "
			.. dims.row_start
			.. ", col_start: "
			.. dims.col_start
	)

	-- Create Metadata and Data windows
	local win_meta = create_floating_window(buffers.buf_meta, {
		title = wins_infos.meta_title,
		width = dims.meta_width,
		height = dims.meta_height,
		row = dims.row_start,
		col = dims.col_start,
	}, opts)

	vim.notify(
		"data width: "
			.. dims.data_width
			.. ", data_height: "
			.. dims.data_height
			.. ", row_start: "
			.. dims.data_row_start
			.. ", col_start: "
			.. dims.data_col_start
	)
	local win_data = create_floating_window(buffers.buf_data, {
		title = wins_infos.data_title,
		width = dims.data_width,
		height = dims.data_height,
		row = dims.data_row_start,
		col = dims.data_col_start,
	}, opts)

	-- Store windows in state
	state.set_state("windows", "win_help", win_help)
	state.set_state("windows", "win_meta", win_meta)
	state.set_state("windows", "win_data", win_data)
	state.set_state("windows", "win_sql", win_sql)
	state.set_state("windows", "win_sql_err", win_sql_err)

	-- Set window highlights
	config_windows.set_window_options(opts)
end

return M
