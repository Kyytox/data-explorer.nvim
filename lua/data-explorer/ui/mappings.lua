local state = require("data-explorer.gestion.state")
local duckdb = require("data-explorer.core.duckdb")
local actions_windows = require("data-explorer.actions.actions_windows")
local actions_render = require("data-explorer.actions.actions_render")
local config_windows = require("data-explorer.ui.config_windows")

local M = {}

--- Sets common keymaps for a given buffer.
---@param opts table: Options table.
function M.set_common_keymaps(opts)
	local buffers = state.get_state("buffers")
	local wins = state.get_state("windows")

	-- Focus controls
	for key, buf in pairs(buffers) do
		local map_opts = { buffer = buf, nowait = true }

		vim.keymap.set("n", opts.mappings.focus_meta, function()
			actions_windows.focus_window(wins.win_meta)
			config_windows.upd_cursorline_option(false, wins.win_data)
			config_windows.upd_cursorline_option(true, wins.win_meta)
		end, map_opts)

		vim.keymap.set("n", opts.mappings.focus_data, function()
			actions_windows.focus_window(wins.win_data)
			config_windows.upd_cursorline_option(true, wins.win_data)
			config_windows.upd_cursorline_option(false, wins.win_meta)
		end, map_opts)

		-- Layout rotation
		vim.keymap.set("n", opts.mappings.rotate_layout, function()
			actions_render.rotate_layout(opts)
		end, map_opts)

		-- Back to file selection
		vim.keymap.set("n", opts.mappings.back, function()
			actions_render.back_to_file_selection(opts)
		end, map_opts)

		-- Close all windows
		vim.keymap.set("n", opts.mappings.quit, function()
			actions_windows.close_windows()
		end, map_opts)

		-- SQL Query window toggle
		vim.keymap.set("n", opts.mappings.toggle_sql, function()
			-- Toggle SQL window and focus on buffer
			actions_windows.toggle_window_focus(wins.win_sql, wins.win_sql, wins.win_data)

			-- Adjust cursorline settings
			config_windows.upd_cursorline_option(false, wins.win_data)
			config_windows.upd_cursorline_option(false, wins.win_meta)
			config_windows.upd_cursorline_option(true, wins.win_sql)

			-- Ensure SQL error window is hidden when SQL window is shown
			local sql_err_hide = vim.api.nvim_win_get_config(wins.win_sql_err).hide
			if not sql_err_hide then
				actions_windows.toggle_window_focus(wins.win_sql_err)
			end
		end, map_opts)
		::continue::
	end

	-- Execution of SQL query
	vim.keymap.set("n", opts.mappings.execute_sql, function()
		local sql_err_hide = vim.api.nvim_win_get_config(wins.win_sql_err).hide
		local err = duckdb.execute_sql_query(buffers.buf_sql)

		if err then
			-- Update buffer with error message
			local err_lines = vim.split(err, "\n")
			vim.api.nvim_buf_set_lines(buffers.buf_sql_err, 0, -1, false, err_lines)

			-- Show SQL error window
			if sql_err_hide then
				actions_windows.toggle_window_focus(wins.win_sql_err, wins.win_sql, nil)
			end

			return
		end

		-- Hide SQL error window if visible because query was successful
		if not sql_err_hide then
			actions_windows.toggle_window_focus(wins.win_sql_err)
		end

		-- Hide SQL window and refocus data window
		actions_windows.toggle_window_focus(wins.win_sql, nil, wins.win_data)

		-- Adjust cursorline settings
		config_windows.upd_cursorline_option(true, wins.win_data)
		config_windows.upd_cursorline_option(false, wins.win_meta)
	end, { buffer = buffers.buf_sql, nowait = true })
end

return M
