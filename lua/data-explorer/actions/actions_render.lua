local utils = require("data-explorer.utils")
local state = require("data-explorer.state")
local log = require("data-explorer.log")
local actions_windows = require("data-explorer.actions.actions_windows")

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
		vim.api.nvim_win_set_config(win_meta, {
			relative = "editor",
			width = dim.main_width,
			height = dim.meta_height,
			row = dim.row_start,
			col = dim.col_start,
		})

		-- Update data window
		vim.api.nvim_win_set_config(win_data, {
			relative = "editor",
			width = dim.main_width,
			height = dim.data_height,
			row = dim.data_row_start,
			col = dim.data_col_start,
		})
	else
		-- Update metadata window
		vim.api.nvim_win_set_config(win_meta, {
			relative = "editor",
			width = dim.meta_width,
			height = dim.meta_height,
			row = dim.row_start,
			col = dim.col_start,
		})

		-- Update data window
		vim.api.nvim_win_set_config(win_data, {
			relative = "editor",
			width = dim.data_width,
			height = dim.data_height,
			row = dim.data_row_start,
			col = dim.data_col_start,
		})
	end
end

--- Go back to file selection function (Uses the main module reference)
---@param opts table: Options table.
function M.back_to_file_selection(opts)
	-- Get files_types from config
	local files_types = opts.files_types

	-- Find all file
	local parquet_files = utils.get_files_in_working_directory(files_types)

	-- Launch Data Explorer
	actions_windows.close_windows()
	state.reset_state("windows")
	state.reset_state("buffers")
	state.reset_state("current_file")

	require("data-explorer.ui.picker").pickers_files(opts, parquet_files)
end

return M
