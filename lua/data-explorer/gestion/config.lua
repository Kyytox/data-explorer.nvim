local config_validation = require("data-explorer.gestion.config_validation")
local log = require("data-explorer.gestion.log")

local M = {}

--- Default configuration options for the plugin.
---@class ConfigOptions
---@field limit number Maximum number of rows to fetch
---@field layout string Layout of the display ("vertical" or "horizontal")
---@field files_types table Supported file types
---@field telescope_opts table Telescope UI options
---@field placeholder_sql table Placeholder SQL query lines
---@field window_opts table Floating window options
---@field mappings table Key mappings
---@field hl table Highlight colors
M.defaults = {
	use_storage_duckdb = false,
	limit = 250, -- Maximum number of rows to fetch
	layout = "vertical", -- Vertical or horizontal
	files_types = {
		parquet = true,
		csv = true,
		tsv = true,
	},

	-- UI/Telescope options
	telescope_opts = {
		layout_strategy = "vertical",
		layout_config = {
			height = 0.7,
			width = 0.9,
			preview_cutoff = 1,
			preview_height = 0.6, -- Used for vertical layout
			preview_width = 0.4, -- Used for horizontal layout
		},
		finder = {
			include_hidden = false, -- Show hidden files
			exclude_dirs = { ".git", "node_modules", "__pycache__", "venv", ".venv", "miniconda3" },
		},
	},

	-- Floating window options for main display windows
	window_opts = {
		border = "rounded",
		max_height_metadata = 0.25,
		max_width_metadata = 0.25,
	},

	-- Query SQL
	query_sql = {
		-- Lines displayed in the SQL window when opened, {} for no placeholder
		placeholder_sql = {
			"SELECT * FROM f",
			"-- To query the file, use 'f' as the table name.",
		},
	},

	-- Key mappings
	mappings = {
		quit = "q", -- Close the main UI
		back = "<BS>", -- Go back to file selection
		next_page = "J", -- Next page of data
		prev_page = "K", -- Previous page of data
		focus_meta = "1", -- Focus the metadata window
		focus_data = "2", -- Focus the data window
		toggle_sql = "3", -- Toggle the SQL query window
		rotate_layout = "r", -- Rotate the layout
		execute_sql = "e", -- Execute the SQL query
	},

	-- Highlight colors
	hl = {
		windows = {
			bg = "#151515",
			fg = "#cdd6f4",
			title = "#D97706",
			footer = "#F87171",
			sql_fg = "#3B82F6",
			sql_bg = "#1e1e2e",
			sql_err_fg = "#EF4444",
			sql_err_bg = "#3b1d2a",
		},
		buffer = {
			hl_enable = true,
			header = "white",
			col1 = "#EF4444",
			col2 = "#3B82F6",
			col3 = "#10B981",
			col4 = "#FBBF24",
			col5 = "#A78BFA",
			col6 = "#06B6D4",
			col7 = "#F59E0B",
			col8 = "#63A5F7",
			col9 = "#22C55E",
		},
	},
}

M.options = {}

--- Set all necessary highlight groups based on provided options.
---@param opts table: Options table containing highlight colors.
local function set_highlights(opts)
	local highlights = {
		{ name = "DataExplorerWindow", opts = { bg = opts.hl.windows.bg } },
		{ name = "DataExplorerBorder", opts = { bg = opts.hl.windows.bg, fg = opts.hl.windows.fg } },
		{ name = "DataExplorerTitle", opts = { bg = opts.hl.windows.bg, fg = opts.hl.windows.title, bold = true } },
		{ name = "DataExplorerFooter", opts = { bg = opts.hl.windows.bg, fg = opts.hl.windows.footer, italic = true } },
		{ name = "DataExplorerSQLBorder", opts = { bg = opts.hl.windows.sql_bg, fg = opts.hl.windows.sql_fg } },
		{ name = "DataExplorerSQLWindow", opts = { bg = opts.hl.windows.sql_bg } },
		{
			name = "DataExplorerSQLErrBorder",
			opts = { bg = opts.hl.windows.sql_err_bg, fg = opts.hl.windows.sql_err_fg },
		},
		{ name = "DataExplorerSQLErrWindow", opts = { bg = opts.hl.windows.sql_err_bg } },
		--
		-- Highlight for buffer content
		{ name = "DataExplorerColHeader", opts = { fg = opts.hl.buffer.header, bold = true } },
		{ name = "DataExplorerCol1", opts = { fg = opts.hl.buffer.col1 } },
		{ name = "DataExplorerCol2", opts = { fg = opts.hl.buffer.col2 } },
		{ name = "DataExplorerCol3", opts = { fg = opts.hl.buffer.col3 } },
		{ name = "DataExplorerCol4", opts = { fg = opts.hl.buffer.col4 } },
		{ name = "DataExplorerCol5", opts = { fg = opts.hl.buffer.col5 } },
		{ name = "DataExplorerCol6", opts = { fg = opts.hl.buffer.col6 } },
		{ name = "DataExplorerCol7", opts = { fg = opts.hl.buffer.col7 } },
		{ name = "DataExplorerCol8", opts = { fg = opts.hl.buffer.col8 } },
		{ name = "DataExplorerCol9", opts = { fg = opts.hl.buffer.col9 } },
	}
	for _, hl in ipairs(highlights) do
		vim.api.nvim_set_hl(0, hl.name, hl.opts)
	end
end

--- Recursively applies default values to the user options.
--- @param user_opts table: User-defined options.
--- @param default table: Default options.
--- @return table: Merged options.
function M.apply_defaults(user_opts, default)
	for key, default_value in pairs(default) do
		if type(key) == "string" then
			local user_value = user_opts[key]
			if type(default_value) == "table" then
				if type(user_value) ~= "table" then
					user_opts[key] = vim.deepcopy(default_value)
				else
					user_opts[key] = M.apply_defaults(user_value, default_value)
				end
			else
				if user_value == nil then
					user_opts[key] = default_value
				end
			end
		end
	end
	return user_opts
end

--- Setup the configuration with user-defined options.
--- @param user_opts table|nil: User-defined options.
function M.setup(user_opts)
	local opts = user_opts or {}

	-- Valid user options
	M.options = config_validation.valid_user_options(M.defaults, opts)

	-- Merge user options with defaults
	M.options = M.apply_defaults(vim.deepcopy(M.options), M.defaults)

	-- Set highlights
	set_highlights(M.options)
end

--- Get the current configuration options.
--- @return table: The current configuration.
function M.get()
	return M.options
end

--- Get the default configuration options.
--- @return table: The default configuration.
function M.get_default_config()
	return M.defaults
end

return M
