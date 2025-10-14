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

	-- Styling/Highlighting (for the floating windows)
	hl_bg = "#171924", -- Background color for the window (e.g., a dark background)
	hl_fg = "#f38ba8", -- Foreground color for the border (e.g., Catppuccin Rosewater)
	hl_title = "#f5c2e7", -- Title color (e.g., Catppuccin Pink)
	hl_footer = "#94e2d5", -- Footer color (e.g., Catpuccin Teal)
	hl_sql_border = "#89b4fa", -- Border color for SQL window (e.g., Catppuccin Blue)
	hl_sql_bg = "#1e1e2e", -- Background color for SQL window (e.g., a dark background)
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
