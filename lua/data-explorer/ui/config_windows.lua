local state = require("data-explorer.gestion.state")
local log = require("data-explorer.gestion.log")

local M = {}

--- Get the appropriate highlight groups for a given window key.
---@param key string: Key identifying the window type.
---@return string: Comma-separated highlight group settings.
local function get_highlight_for_window(key)
	local window_highlights = {
		win_sql = "Normal:DataExplorerSQLWindow,FloatBorder:DataExplorerSQLBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
		win_sql_err = "Normal:DataExplorerSQLErrWindow,FloatBorder:DataExplorerSQLErrBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
		default = "Normal:DataExplorerWindow,FloatBorder:DataExplorerBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
	}
	return window_highlights[key] or window_highlights.default
end

--- Update cursorline window options
---@param bool boolean: Whether to enable or disable cursorline.
---@param win integer: Window handle.
function M.upd_cursorline_option(bool, win)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_option_value("cursorline", bool, { win = win, scope = "local" })
	end
end

--- Set window options and highlights for all managed windows.
function M.set_window_options()
	local wins = state.get_state("windows")

	-- Set window options and highlights
	for key, win in pairs(wins) do
		local highlight = get_highlight_for_window(key)
		vim.wo[win].winhighlight = highlight
		vim.api.nvim_set_option_value("wrap", false, { win = win, scope = "local" })
	end

	-- Enable cursorline for the data window by default
	M.upd_cursorline_option(true, wins.win_data)
end

--- Calculate window layout for both vertical and horizontal layouts.
---@param opts table: Options table.
---@param width number: Width of the available space.
---@param height number: Height of the available space.
---@param nb_metadata_lines number: Number of lines in the metadata content.
---@param nb_data_lines number: Number of lines in the data content.
---@return table: Calculated dimensions for both vertical and horizontal layouts.
function M.calculate_window_layout(opts, width, height, nb_metadata_lines, nb_data_lines)
	-- Help window height
	local height_help = 1
	local row_start = height_help + 3

	-- SQL windows
	local sql_row_start = math.floor(height * 0.3)
	local sql_height = 7
	local sql_err_row_start = sql_row_start + sql_height + 2
	local sql_err_height = 7

	-- Adjust if help window is hidden
	if opts.window_opts.hide_window_help == true then
		height_help = 0
		row_start = 1
	end

	local col_start = 1
	local available_height = height - row_start
	local main_width = math.floor(width * 0.98)

	-- Vertical layout
	-- determine max height
	local max_meta_height_v = math.floor(available_height * 0.30)
	local max_data_height_v = math.floor(available_height * 0.68)

	-- Calcul heights
	local meta_height_v = math.min(nb_metadata_lines, max_meta_height_v)
	local data_height_v = math.min(nb_data_lines, max_data_height_v) + 1

	-- Calculate data row start
	local data_row_start_v = row_start + meta_height_v + 2

	-- Horizontal layout
	-- Calculate widths
	local meta_width_h = math.floor(main_width * 0.25)
	local data_width_h = main_width - meta_width_h - col_start

	-- Calculate heights
	local meta_height_h = 0
	local data_height_h = 0
	if nb_metadata_lines > nb_data_lines then
		meta_height_h = math.min(nb_metadata_lines, available_height)
		data_height_h = meta_height_h
	else
		data_height_h = math.min(nb_data_lines, available_height)
		meta_height_h = data_height_h
	end

	-- Calculate data column start
	local data_col_start_h = col_start + meta_width_h + 2

	--
	local dimensions = {
		horizontal = {
			meta_width = meta_width_h,
			meta_height = meta_height_h,
			data_width = data_width_h,
			data_height = data_height_h,
			data_col_start = data_col_start_h,
			data_row_start = row_start,
			help_height = height_help,
			sql_row_start = sql_row_start,
			sql_height = sql_height,
			sql_err_row_start = sql_err_row_start,
			sql_err_height = sql_err_height,
			main_width = main_width,
			row_start = row_start,
			col_start = col_start,
			height = height,
		},
		vertical = {
			meta_width = main_width, -- full width
			meta_height = meta_height_v,
			data_width = main_width, -- full width
			data_height = data_height_v,
			data_col_start = col_start,
			data_row_start = data_row_start_v,
			help_height = height_help,
			sql_height = sql_height,
			sql_row_start = sql_row_start,
			sql_err_row_start = sql_err_row_start,
			sql_err_height = sql_err_height,
			main_width = main_width,
			row_start = row_start,
			col_start = col_start,
			height = height,
		},
	}

	state.set_state("tbl_dimensions", nil, dimensions)
	return dimensions
end

return M
