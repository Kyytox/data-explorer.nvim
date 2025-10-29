local config_windows = require("data-explorer.ui.config_windows")
local state = require("data-explorer.gestion.state")
local display = require("data-explorer.ui.display")
local log = require("data-explorer.gestion.log")

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
		footer_pos = wins_infos.footer_pos or "left",
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
	-- actions_windows.close_windows()

	-- Get windows infos
	local wins_infos = state.get_variable("windows_infos")

	-- Retrieve buffers from state
	local buffers = state.get_state("buffers")

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

	-- Create Metadata and Data windows
	local win_meta = create_floating_window(buffers.buf_meta, {
		title = wins_infos.meta_title,
		width = dims.meta_width,
		height = dims.meta_height,
		row = dims.row_start,
		col = dims.col_start,
	}, opts)

	local win_data = create_floating_window(buffers.buf_data, {
		title = wins_infos.data_title,
		width = dims.data_width,
		height = dims.data_height,
		row = dims.data_row_start,
		col = dims.data_col_start,
		footer = table.concat(display.prepare_help(opts), "\n") or nil,
		footer_pos = "right",
	}, opts)

	-- Store window handles in state
	-- Store all in one, because with WinEnter (autocmd) the time between creations can cause issues
	state.set_state("windows", "win_meta", win_meta)
	state.set_state("windows", "win_data", win_data)
	state.set_state("windows", "win_sql", win_sql)
	state.set_state("windows", "win_sql_err", win_sql_err)

	-- Set window highlights
	config_windows.set_window_options()
end

return M
