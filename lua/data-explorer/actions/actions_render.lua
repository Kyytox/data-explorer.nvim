local utils = require("data-explorer.utils")
local state = require("data-explorer.state")

local M = {}

--- Rotate between vertical and horizontal layouts.
---@param opts table: Options table.
---@param layout string: Current layout ("vertical" or "horizontal").
function M.rotate_layout(opts, layout)
	-- Update the options table for the next call
	opts.layout = layout == "vertical" and "horizontal" or "vertical"
	local wins_layout = state.get_state("windows_layout")

	-- Recreate windows with the new layout
	require("data-explorer.ui.windows").create_windows(opts, opts.layout, wins_layout)
end

--- Go back to file selection function (Uses the main module reference)
---@param opts table: Options table.
function M.back_to_file_selection(opts)
	vim.notify("Back to file selection", vim.log.levels.INFO)
	-- Find all .parquet file
	local parquet_files = utils.get_files_in_working_directory()

	-- Launch Data Explorer
	state.reset_state()
	require("data-explorer.ui.picker").pickers_files(opts, parquet_files)
end

return M
