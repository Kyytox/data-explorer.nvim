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
	local width = wins_infos.width or math.floor(vim.o.columns * 0.7)
	local height = wins_infos.height or math.floor(vim.o.lines * 0.6)

	local conf = {
		title = wins_infos.title,
		title_pos = wins_infos.title_pos or "left",
		relative = "editor",
		width = width,
		height = height,
		row = wins_infos.row or math.floor((vim.o.lines - height) / 2),
		col = wins_infos.col or math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = opts.window_opts.border or "rounded",
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
---@param wins_layout table: Calculated window layout parameters.
---@param opts table: Options table.
function M.create_windows(opts, wins_layout)
	-- Clean up old windows
	actions_windows.close_windows()

	-- Get windows infos
	local wins_infos = state.get_variable("windows_infos")

	-- Retrieve buffers from state
	local buffers = state.get_state("buffers")

	local win_help = create_floating_window(buffers.buf_help, {
		title = wins_infos.help_title,
		width = wins_layout.main_width,
		height = wins_layout.height_help,
		row = 1,
		col = wins_layout.col_start,
	}, opts)

	-- Windows for Query buf_sql
	local win_sql = create_floating_window(buffers.buf_sql, {
		title = wins_infos.sql_title,
		title_pos = "left",
		width = wins_layout.main_width,
		height = 7,
		row = math.floor(wins_layout.height) * 0.3,
		col = wins_layout.col_start,
		hide = true,
		-- footer = tostring(buffers.buf_sql_help),
	}, opts)

	-- Windows for Query buf_sql
	local win_sql_err = create_floating_window(buffers.buf_sql_err, {
		title = wins_infos.sql_err_title,
		title_pos = "left",
		width = wins_layout.main_width,
		height = 7,
		row = math.floor(wins_layout.height) * 0.3 + 9,
		col = wins_layout.col_start,
		hide = true,
	}, opts)

	-- Windows for Metadata and Data
	local win_meta, win_data

	if layout == "vertical" then
		-- Vertical Layout
		win_meta = create_floating_window(buffers.buf_meta, {
			title = wins_infos.meta_title,
			width = wins_layout.main_width,
			height = wins_layout.metadata_height,
			row = wins_layout.row_start,
			col = wins_layout.col_start,
		}, opts)

		win_data = create_floating_window(buffers.buf_data, {
			title = wins_infos.data_title,
			width = wins_layout.main_width,
			height = wins_layout.data_height,
			row = wins_layout.row_start + wins_layout.metadata_height + 2, -- Directly stack them
			col = wins_layout.col_start,
		}, opts)
	else
		win_meta = create_floating_window(buffers.buf_meta, {
			title = wins_infos.meta_title,
			width = meta_width,
			height = height_combined,
			row = wins_layout.row_start,
			col = wins_layout.col_start,
		}, opts)

		win_data = create_floating_window(buffers.buf_data, {
			title = wins_infos.data_title,
			width = data_width,
			height = height_combined,
			row = wins_layout.row_start,
			col = wins_layout.col_start + meta_width + 2, -- Place next to metadata
		}, opts)
	end

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
