local utils = require("data-explorer.core.utils")
local state = require("data-explorer.gestion.state")
local log = require("data-explorer.gestion.log")
local actions_windows = require("data-explorer.actions.actions_windows")
local config_windows = require("data-explorer.ui.config_windows")

local M = {}

--- Rotate between vertical and horizontal layouts.
---@param opts table: Options table.
function M.rotate_layout(opts)
	-- Get current layout
	local current_layout = state.get_state("current_layout")

	-- Toggle layout
	local new_layout
	if current_layout == "vertical" then
		new_layout = "horizontal"
	else
		new_layout = "vertical"
	end
	state.set_state("current_layout", nil, new_layout)

	-- Get dimensions for the new layout
	local dim = state.get_state("tbl_dimensions", new_layout)

	-- Get window handles
	local win_meta = state.get_state("windows", "win_meta")
	local win_data = state.get_state("windows", "win_data")

	-- Update data window
	if new_layout == "vertical" then
		-- Update metadata window
		config_windows.update_window_dimensions(win_meta, dim.main_width, dim.meta_height, dim.row_start, dim.col_start)

		-- Update data window
		config_windows.update_window_dimensions(
			win_data,
			dim.main_width,
			dim.data_height,
			dim.data_row_start,
			dim.data_col_start
		)
	else
		-- Update metadata window
		config_windows.update_window_dimensions(win_meta, dim.meta_width, dim.meta_height, dim.row_start, dim.col_start)

		-- Update data window
		config_windows.update_window_dimensions(
			win_data,
			dim.data_width,
			dim.data_height,
			dim.data_row_start,
			dim.data_col_start
		)
	end
end

--- Go back to file selection function (Uses the main module reference)
---@param opts table: Options table.
function M.back_to_file_selection(opts)
	-- exctract file types from opts.files_types
	local files_types = utils.aggregate_file_types(opts)

	-- Launch Data Explorer
	actions_windows.close_windows()
	state.reset_state("windows")
	state.reset_state("buffers")
	state.reset_state("current_file")

	require("data-explorer.ui.picker").pickers_files(opts, files_types)
end

return M
