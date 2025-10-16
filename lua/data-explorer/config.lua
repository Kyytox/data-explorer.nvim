local log = require("data-explorer.log")

local M = {}

--- Default configuration options for the plugin.
M.defaults = {
	-- Data fetching options
	limit = 20, -- Number of rows to display in the data preview window.
	duckdb_cmd = "duckdb", -- Command used to execute DuckDB.
	layout = "vertical", -- Initial layout ("vertical" or "horizontal") for the main display.

	-- UI/Telescope options
	telescope_opts = { -- Options passed directly to telescope.new()
		layout_config = {
			height = 0.5,
			width = 0.9,
			preview_cutoff = 1,
		},
	},

	-- Floating window options
	window_opts = {
		border = "rounded", -- Border style for floating windows.
	},

	-- Key mappings
	mappings = {
		quit = "q", -- Key to quit/close the main UI
		back = "<BS>", -- Key to go back to file selection
		focus_meta = "1", -- Key to focus the metadata window
		focus_data = "2", -- Key to focus the data window
		rotate_layout = "r", -- Key to rotate the layout (not implemented yet)
		toggle_sql = "s", -- Key to toggle the SQL query window
		execute_sql = "e", -- Key to execute the SQL query
	},

	-- Styling/Highlighting (for the floating windows)
	hl_bg = "#171924", -- Background color for the window
	hl_fg = "#f38ba8", -- Foreground color for the border
	hl_title = "#f5c2e7", -- Title color
	hl_footer = "#94e2d5", -- Footer color
	hl_sql_fg = "#89b4fa", -- Border color for SQL window
	hl_sql_bg = "#1e1e2e", -- Background color for SQL window
	hl_sql_err_fg = "#c0653c", -- Border color for SQL error window
	hl_sql_err_bg = "#431e2e", -- Background color for SQL
}

--- The current, merged configuration. This is what the rest of the plugin uses.
M.options = {}

--- Merges user options with defaults and stores the result.
--- @param user_opts table|nil: User-defined options.
function M.setup(user_opts)
	-- Create a copy of defaults to modify
	local opts = vim.deepcopy(M.defaults)

	-- Merge the user_opts into the defaults copy
	if type(user_opts) == "table" then
		M.options = vim.tbl_deep_extend("force", opts, user_opts)
	else
		M.options = opts
	end

	-- Update Telescope layout configuration based on initial layout_strategy
	local is_vertical = M.options.layout == "vertical"
	M.options.telescope_opts.layout_config.preview_height = is_vertical and 0.4 or nil
	M.options.telescope_opts.layout_config.preview_width = not is_vertical and 0.4 or nil
end

--- Get the current configuration options.
--- @return table: The current configuration.
function M.get()
	return M.options
end

return M
