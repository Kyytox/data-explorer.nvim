local state = require("data-explorer.gestion.state")

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

	-- Adjust if help window is hidden
	if opts.window_opts.hide_window_help == true then
		height_help = 0
		row_start = 1
	end

	-- Common parameters
	local col_start = 2
	local available_height = height - row_start
	local main_width = math.floor(width * 0.97)

	-- SQL windows
	local sql_row_start = math.floor(height * 0.3)
	local sql_height = 7
	local sql_err_row_start = sql_row_start + sql_height + 2
	local sql_err_height = 7

	-- Vertical layout
	local meta_width_v = main_width
	local data_width_v = main_width
	local data_row_start_v = row_start + nb_metadata_lines + 2

	-- Calculate target heights
	local total_content_height = nb_metadata_lines + nb_data_lines
	local target_height_meta = math.floor(available_height * 0.4)
	local target_height_data = available_height - target_height_meta
	local meta_height_v = math.max(4, math.min(nb_metadata_lines, target_height_meta))
	local data_height_v = math.max(8, math.min(nb_data_lines, target_height_data))

	-- Adjust if content is less than available height
	if total_content_height < available_height then
		meta_height_v = math.max(4, math.min(nb_metadata_lines, math.ceil(total_content_height * 0.4)))
		data_height_v = math.max(8, total_content_height - meta_height_v)
	end

	-- Horizontal layout
	local meta_width_h = math.floor(main_width * 0.35)
	local data_width_h = main_width - meta_width_h - col_start
	-- local meta_height_h = math.max(4, math.min(nb_metadata_lines, available_height))
	local data_height_h = math.max(8, math.min(nb_data_lines, available_height))
	local data_col_start_h = col_start + meta_width_h + 2

	--
	local dimensions = {
		horizontal = {
			meta_width = meta_width_h,
			meta_height = data_height_h,
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
			meta_width = meta_width_v,
			meta_height = meta_height_v,
			data_width = data_width_v,
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
