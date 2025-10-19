local log = require("data-explorer.gestion.log")

local M = {}

--- Default configuration options for the plugin.
---@class ConfigOptions
---@field limit number: Maximum number of rows to fetch from the data file.
---@field layout string|nil: Layout of the display windows ("vertical" or "horizontal").
---@field files_types table: List of supported file types.
---@field telescope_opts table: Options for Telescope picker.
---@field window_opts table: Options for floating windows.
---@field mappings table: Key mappings for various actions.
---@field hl table: Highlight colors for UI elements.
M.defaults = {
	-- Data fetching options
	limit = 10000, -- Maximum number of rows to fetch
	layout = "vertical", -- Vertical or horizontal
	files_types = { ".parquet", ".csv", ".tsv" },

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
	},

	-- Floating window options for main display windows
	window_opts = {
		border = "rounded",
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
		bg = "#171924", -- Background color for the window
		fg = "#f38ba8", -- Foreground color for the border
		title = "#f5c2e7", -- Title color
		footer = "#94e2d5", -- Footer color
		sql_fg = "#89b4fa", -- Border color for SQL window
		sql_bg = "#1e1e2e", -- Background color for SQL window
		sql_err_fg = "#c0653c", -- Border color for SQL error window
		sql_err_bg = "#3a1726", -- Background color for SQL
	},
}

M.options = {}

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

-- Check for valid options
local function validate_options(opts)
	-- Ensure limit is a positive integer
	if type(opts.limit) ~= "number" or opts.limit <= 0 then
		log.display_notify(3, "limit must be a positive number. Reverting to default.")
		opts.limit = M.defaults.limit
	end

	-- Ensure layout is valid
	if opts.layout ~= "vertical" and opts.layout ~= "horizontal" then
		log.display_notify(3, 'layout must be "vertical" or "horizontal". Reverting to default.')
		opts.layout = M.defaults.layout
	end

	-- Ensure files_types is a table
	if type(opts.files_types) ~= "table" then
		log.display_notify(3, "files_types must be a table. Reverting to default.")
		opts.files_types = M.defaults.files_types
	end
end

---@param opts table
---@param defaults table
---@return table
local function apply_defaults(opts, defaults)
	for k, v in pairs(defaults) do
		if opts[k] == nil then
			opts[k] = vim.deepcopy(v)
		elseif type(opts[k]) == "table" and type(v) == "table" then
			apply_defaults(opts[k], v)
		end
	end
	return opts
end

---Merges user options with defaults and stores the result.
--- @param user_opts table|nil: User-defined options.
function M.setup(user_opts)
	local opts = user_opts or {}
	-- Deep merge user options with defaults
	-- M.options = vim.tbl_deep_extend("force", M.defaults, opts)
	M.options = apply_defaults(vim.deepcopy(opts), M.defaults)

	-- Validate options
	validate_options(M.options)

	-- Set all highlight groups
	set_highlights(M.options)
	-- vim.notify = require("notify")
	vim.notify(vim.inspect(M.options), vim.log.levels.INFO, { title = "Data Explorer Config" })
	-- log.display_notify(1, vim.inspect(M.options))
end

--- Get the current configuration options.
--- @return table: The current configuration.
function M.get()
	return M.options
end

return M
