local state = require("data-explorer.state")

local M = {}

--- Get the appropriate highlight groups for a given window key.
---@param key string: Key identifying the window type.
---@return string: Comma-separated highlight group settings.
local function get_highlight_for_window(key)
	local window_highlights = {
		win_sql = "Normal:DataExplorerSQLWindow,FloatBorder:DataExplorerSQLBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
		win_sql_err = "Normal:DataExplorerSQLErrWindow,FloatBorder:DataExplorerSQLErrBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
		-- Default for all other windows
		default = "Normal:DataExplorerWindow,FloatBorder:DataExplorerBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
	}
	return window_highlights[key] or window_highlights.default
end

--- Set all necessary highlight groups based on provided options.
---@param opts table: Options table containing highlight colors.
local function set_highlights(opts)
	local highlights = {
		{ name = "DataExplorerWindow", opts = { bg = opts.hl.bg } },
		{ name = "DataExplorerBorder", opts = { bg = opts.hl.bg, fg = opts.hl.fg } },
		{ name = "DataExplorerTitle", opts = { bg = opts.hl.bg, fg = opts.hl.title, bold = true } },
		{ name = "DataExplorerFooter", opts = { bg = opts.hl.bg, fg = opts.hl.footer, italic = true } },
		{ name = "DataExplorerSQLBorder", opts = { bg = opts.hl.sql_bg, fg = opts.hl.sql_fg } },
		{ name = "DataExplorerSQLWindow", opts = { bg = opts.hl.sql_bg } },
		{ name = "DataExplorerSQLErrBorder", opts = { bg = opts.hl.sql_err_bg, fg = opts.hl.sql_err_fg } },
		{ name = "DataExplorerSQLErrWindow", opts = { bg = opts.hl.sql_err_bg } },
	}
	for _, hl in ipairs(highlights) do
		vim.api.nvim_set_hl(0, hl.name, hl.opts)
	end
end

--- Set window options and highlights for all managed windows.
---@param opts table: Options table containing highlight colors.
function M.set_window_options(opts)
	local wins = state.get_state("windows")

	-- Set all highlight groups
	set_highlights(opts)

	-- Set window options and highlights
	for key, win in pairs(wins) do
		local highlight = get_highlight_for_window(key)
		vim.api.nvim_set_option_value("wrap", false, { win = win, scope = "local" })
		vim.wo[win].winhighlight = highlight
	end
end

--- Calculate window layout for both vertical and horizontal layouts.
---@param nb_metadata_lines number: Number of lines in the metadata content.
---@param nb_data_lines number: Number of lines in the data content.
---@return table: Calculated dimensions for both vertical and horizontal layouts.
function M.calculate_window_layout(nb_metadata_lines, nb_data_lines)
	local width, height = vim.o.columns, vim.o.lines
	vim.notify("Screen (width, height): " .. width .. "x" .. height)

	-- Common parameters
	local col_start = 2
	local height_help = 1
	local row_start = height_help + 3
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
	local meta_height_h = math.max(4, math.min(nb_metadata_lines, available_height))
	local data_height_h = math.max(8, math.min(nb_data_lines, available_height))
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
