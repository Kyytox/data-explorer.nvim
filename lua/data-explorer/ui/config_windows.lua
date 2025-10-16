local state = require("data-explorer.state")

local M = {}

--- Sets common window local options and highlights.
---@param opts table: Configuration options including highlight settings.
function M.set_window_options(opts)
	local wins = state.get_state("windows")
	local highlight = ""

	-- Set global highlights for the theme
	vim.api.nvim_set_hl(0, "DataExplorerWindow", { bg = opts.hl_bg })
	vim.api.nvim_set_hl(0, "DataExplorerBorder", { bg = opts.hl_bg, fg = opts.hl_fg })
	vim.api.nvim_set_hl(0, "DataExplorerTitle", { bg = opts.hl_bg, fg = opts.hl_title, bold = true })
	vim.api.nvim_set_hl(0, "DataExplorerFooter", { bg = opts.hl_bg, fg = opts.hl_footer, italic = true })
	vim.api.nvim_set_hl(0, "DataExplorerSQLBorder", { bg = opts.hl_sql_bg, fg = opts.hl_sql_fg })
	vim.api.nvim_set_hl(0, "DataExplorerSQLWindow", { bg = opts.hl_sql_bg })
	vim.api.nvim_set_hl(0, "DataExplorerSQLErrBorder", { bg = opts.hl_sql_err_bg, fg = opts.hl_sql_err_fg })
	vim.api.nvim_set_hl(0, "DataExplorerSQLErrWindow", { bg = opts.hl_sql_err_bg })

	-- Determine highlight group based on window type
	for key, win in pairs(wins) do
		if key == "win_sql" then
			highlight =
				"Normal:DataExplorerSQLWindow,FloatBorder:DataExplorerSQLBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter"
		elseif key == "win_sql_err" then
			highlight =
				"Normal:DataExplorerSQLErrWindow,FloatBorder:DataExplorerSQLErrBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter"
		else
			highlight =
				"Normal:DataExplorerWindow,FloatBorder:DataExplorerBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter"
		end

		-- Common window options
		vim.api.nvim_set_option_value("wrap", false, { win = win, scope = "local" })

		-- Set window highlight
		vim.wo[win].winhighlight = highlight
	end
end

--- Calculate window layout for both vertical and horizontal layouts.
---@param nb_metadata_lines number: Number of lines in the metadata content.
---@param nb_data_lines number: Number of lines in the data content.
---@return table: Calculated dimensions for both vertical and horizontal layouts.
function M.calculate_window_layout(nb_metadata_lines, nb_data_lines)
	local width, height = vim.o.columns, vim.o.lines

	-- 1. Common variables
	local height_help = 1
	local row_start = height_help + 3
	local available_height = height - row_start
	local col_start = math.floor(width * 0.01)
	local main_width = math.floor(width * 0.98)

	-- 2. Vertical Layout
	local total_content_height = nb_metadata_lines + nb_data_lines
	local target_height_meta = math.floor(available_height * 0.4)
	local target_height_data = available_height - target_height_meta
	local metadata_height = math.max(4, math.min(nb_metadata_lines, target_height_meta))
	local data_height = math.max(8, math.min(nb_data_lines, target_height_data))

	if total_content_height < available_height then
		metadata_height = math.max(4, math.min(nb_metadata_lines, math.ceil(total_content_height * 0.4)))
		data_height = math.max(8, total_content_height - metadata_height)
	end

	-- 3. Horizontal Layout
	local meta_width = math.floor(main_width * 0.35)
	local data_width = main_width - meta_width - col_start
	local combined_height = metadata_height + data_height
	local height_combined = math.min(combined_height, available_height)

	-- 4. Return both layouts with your requested structure
	local dimensions = {
		vertical = {
			width = math.floor(width * 0.7),
			height = math.floor(height * 0.6),
			row_start = row_start,
			col_start = col_start,
			main_width = main_width,
			meta_width = meta_width,
			data_width = data_width,
			metadata_height = metadata_height,
			data_height = data_height,
			help_height = height_help,
		},
		horizontal = {
			width = math.floor(width * 0.9),
			height = math.floor(height * 0.7),
			row_start = row_start,
			col_start = col_start,
			main_width = main_width,
			meta_width = meta_width,
			data_width = data_width,
			metadata_height = height_combined,
			data_height = height_combined,
			help_height = height_help,
		},
	}

	state.set_state("window_layout", nil, dimensions)
	return dimensions
end

return M
