local log = require("data-explorer.log")

local M = {}

--- Default configuration options for the plugin.
---@class ConfigOptions
---@field limit integer Number of rows to display in the data preview window.
---@field duckdb_cmd string Command used to execute DuckDB.
---@field layout string Layout for the main display ("vertical" or "horizontal").
---@field telescope_opts table Options passed directly to `telescope.new()`.
---@field window_opts table Border style and other options for floating windows.
---@field mappings table Key mappings for the plugin (value can be string or false to disable).
---@field hl table Highlight colors/groups for various UI elements.
M.defaults = {
	-- Data fetching options
	limit = 20,
	duckdb_cmd = "duckdb",
	layout = "vertical", -- Must be "vertical" or "horizontal"
	files_types = { ".parquet", ".csv", ".tsv", ".orc" },

	-- UI/Telescope options
	telescope_opts = {
		layout_config = {
			height = 0.5,
			width = 0.9,
			preview_cutoff = 1,
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
		rotate_layout = "r", -- Rotate the layout
		toggle_sql = "s", -- Toggle the SQL query window
		execute_sql = "e", -- Execute the SQL query
	},

	-- Highlight colors (using Catppuccin-like colors as defaults for example)
	-- hl = {
	-- 	bg = "#171924", -- Background (base/mantle)
	-- 	fg = "#cdd6f4", -- Foreground (text)
	-- 	title = "#89b4fa", -- Title (blue)
	-- 	footer = "#a6e3a1", -- Footer (green)
	-- 	sql_fg = "#f9e2af", -- SQL Window Border (yellow)
	-- 	sql_bg = "#1e1e2e", -- SQL Window Background (crust)
	-- 	sql_err_fg = "#f38ba8", -- SQL Error Border (red/maroon)
	-- 	sql_err_bg = "#313244", -- SQL Error Background (surface)
	-- },
	hl = {
		bg = "#171924", -- Background color for the window
		fg = "#f38ba8", -- Foreground color for the border
		title = "#f5c2e7", -- Title color
		footer = "#94e2d5", -- Footer color
		sql_fg = "#89b4fa", -- Border color for SQL window
		sql_bg = "#1e1e2e", -- Background color for SQL window
		sql_err_fg = "#c0653c", -- Border color for SQL error window
		sql_err_bg = "#431e2e", -- Background color for SQL
	},
}

M.options = {}

--- Merges user options with defaults and stores the result.
--- @param user_opts table|nil: User-defined options.
function M.setup(user_opts)
	local opts_to_merge = vim.deepcopy(M.defaults)

	-- Deeply merge user options over defaults
	if type(user_opts) == "table" then
		-- "force" ensures that nested tables are merged, not overwritten entirely,
		-- which is what we want for mappings, hl, and telescope_opts.
		M.options = vim.tbl_deep_extend("force", opts_to_merge, user_opts)
	else
		M.options = opts_to_merge
	end

	-- Post-processing: Adjust Telescope layout configuration based on the final 'layout' option
	local is_vertical = M.options.layout == "vertical"

	-- Telescope uses preview_height for vertical layout and preview_width for horizontal
	M.options.telescope_opts.layout_config.preview_height = is_vertical and 0.4 or nil
	M.options.telescope_opts.layout_config.preview_width = not is_vertical and 0.4 or nil
end

--- Get the current configuration options.
--- @return table: The current configuration.
function M.get()
	return M.options
end

return M
