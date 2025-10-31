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
			height = 0.4,
			width = 0.9,
			preview_cutoff = 1,
			preview_height = 0.5, -- Used for vertical layout
			preview_width = 0.4, -- Used for horizontal layout
		},
		finder = {
			include_hidden = false, -- Show hidden files
			exclude_dirs = { ".git", "node_modules", "__pycache__", "venv", ".venv" },
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
		-- Lines displayed in the SQL window when opened
		placeholder_sql = {
			"SELECT * FROM f LIMIT 1000;",
			"-- Warning: Large result could slow down / crash.",
			"-- To query the file, use 'f' as the table name.",
		},
	},

	-- Key mappings
	mappings = {
		quit = "q", -- Close the main UI
		back = "<BS>", -- Go back to file selection
		focus_meta = "1", -- Focus the metadata window
		focus_data = "2", -- Focus the data window
		toggle_sql = "3", -- Toggle the SQL query window
		rotate_layout = "r", -- Rotate the layout
		execute_sql = "e", -- Execute the SQL query
	},

	-- Highlight colors
	hl = {
		windows = {
			bg = "#11111b",
			fg = "#cdd6f4",
			title = "#f5c2e7",
			footer = "#a6e3a1",
			sql_fg = "#89b4fa",
			sql_bg = "#1e1e2e",
			sql_err_fg = "#f38ba8",
			sql_err_bg = "#3b1d2a",
		},
		buffer = {
			hl_enable = true,
			header = "white",
			col1 = "#f38ba8",
			col2 = "#89b4fa",
			col3 = "#a6e3a1",
			col4 = "#f9e2af",
			col5 = "#cba6f7",
			col6 = "#94e2d5",
			col7 = "#f5c2e7",
			col8 = "#89b4fa",
			col9 = "#a6e3a1",
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

--- Recursively apply default options to user-provided options.
---@param opts table -- User-provided options.
---@param defaults table -- Default options.
---@return table -- Merged options.
function M.apply_defaults(opts, defaults)
	for k, v in pairs(defaults) do
		if opts[k] == nil then
			opts[k] = vim.deepcopy(v)
		elseif type(opts[k]) == "table" and type(v) == "table" then
			M.apply_defaults(opts[k], v)
		end
	end
	return opts
end

---Merges user options with defaults and stores the result.
--- @param user_opts table|nil: User-defined options.
function M.setup(user_opts)
	local opts = user_opts or {}
	-- Deep merge user options with defaults
	M.options = M.apply_defaults(vim.deepcopy(opts), M.defaults)

	-- Validate options
	log.info("Validating configuration options...")
	config_validation.validate_options(M.defaults, M.options)

	-- Set all highlight groups
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
