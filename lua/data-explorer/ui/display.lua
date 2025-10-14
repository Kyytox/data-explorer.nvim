local M = {}
local windows = require("data-explorer.ui.windows")
local utils = require("data-explorer.utils")

---@type table: Cache for main window and buffer handles.
M.main_windows = {}

---- Clears all main window and buffer handles.
local function clear_main_handles()
	windows.close_windows(vim.tbl_values(M.main_windows))
	M.main_windows = {}
end

--- Go back to file selection function (Uses the main module reference)
---@param M_CORE table: Reference to the main plugin module.
---@param opts table: Options table.
local function back_to_file_selection(M_CORE, opts)
	clear_main_handles() -- Clears main display windows
	M_CORE.select_parquet_file(opts) -- Calls the main entry point again
end

--- Sets common keymaps for a given buffer.
---@param buf number: Buffer ID to set keymaps on.
---@param M_CORE table: Reference to the main plugin module.
---@param opts table: Options table.
---@param rotate_layout_fn fun(): Function to rotate the layout.
local function set_common_keymaps(buf, M_CORE, opts, rotate_layout_fn)
	local main_wins = vim.tbl_values(M.main_windows)

	local map_opts = { buffer = buf, nowait = true }

	-- Focus controls
	vim.keymap.set("n", "1", function()
		windows.focus_window(M.main_windows.win_meta)
	end, map_opts)
	vim.keymap.set("n", "2", function()
		windows.focus_window(M.main_windows.win_data)
	end, map_opts)

	-- Plugin controls
	vim.keymap.set("n", "r", rotate_layout_fn, map_opts)
	vim.keymap.set("n", "<BS>", function()
		back_to_file_selection(M_CORE, opts)
	end, map_opts)
	vim.keymap.set("n", "q", function()
		windows.close_windows(main_wins)
	end, map_opts)

	-- SQL Query window toggle
	vim.keymap.set("n", "s", function()
		local is_visible = windows.toggle_hdie_window(M.main_windows.win_sql)

		-- Restore focus to data window if SQL window is hidden
		if not is_visible then
			windows.focus_window(M.main_windows.win_data)
		end
	end, map_opts)
end

--- Defines all keymaps for the metadata and data buffers. (Same as before)
local function set_keymaps(M_CORE, opts, rotate_layout_fn)
	for _, buf in ipairs({ M.main_windows.buf_meta, M.main_windows.buf_data, M.main_windows.buf_sql }) do
		set_common_keymaps(buf, M_CORE, opts, rotate_layout_fn)
	end
end

--- Check if the currently focused window is one of the main plugin windows.
local function is_plugin_window_focused()
	local current_win = vim.api.nvim_get_current_win()
	-- Check against the window handles (win_meta, win_data, win_help)
	for _, win_id in ipairs(vim.tbl_values(M.main_windows)) do
		-- Only check if it's an actual window handle (not a buffer handle)
		if type(win_id) == "number" and vim.api.nvim_win_is_valid(win_id) and current_win == win_id then
			return true
		end
	end
	return false
end

--- Closes all main plugin windows.
local function close_all_plugin_windows()
	-- This simply calls the existing cleanup function
	clear_main_handles()
end

--- Checks focus and closes the main UI if focus is lost.
function M.check_focus_and_close()
	-- If there are no main windows open, we do nothing.
	if vim.tbl_isempty(M.main_windows) then
		return
	end

	-- If the currently active window is NOT one of our main windows, close them all.
	if not is_plugin_window_focused() then
		close_all_plugin_windows()
	end
end

--- Sets common window local options and highlights.
local function set_window_options(wins, opts)
	local highlight = ""

	-- Set global highlights for the theme
	vim.api.nvim_set_hl(0, "DataExplorerWindow", { bg = opts.hl_bg })
	vim.api.nvim_set_hl(0, "DataExplorerBorder", { bg = opts.hl_bg, fg = opts.hl_fg })
	vim.api.nvim_set_hl(0, "DataExplorerTitle", { bg = opts.hl_bg, fg = opts.hl_title, bold = true })
	vim.api.nvim_set_hl(0, "DataExplorerFooter", { bg = opts.hl_bg, fg = opts.hl_footer, italic = true })
	vim.api.nvim_set_hl(0, "DataExplorerSQLBorder", { bg = opts.hl_sql_bg, fg = opts.hl_sql_border })
	vim.api.nvim_set_hl(0, "DataExplorerSQLWindow", { bg = opts.hl_sql_bg })

	-- Set window local options
	for _, win in ipairs(wins) do
		if win == M.main_windows.win_sql then
			highlight =
				"Normal:DataExplorerSQLWindow,FloatBorder:DataExplorerSQLBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter"
		else
			highlight =
				"Normal:DataExplorerWindow,FloatBorder:DataExplorerBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter"
		end
		vim.api.nvim_set_option_value("wrap", false, { win = win, scope = "local" })
		vim.wo[win].winhighlight = highlight
	end
end

--- Render the main display with metadata, data, and help.
---@param M_CORE table: Reference to the main plugin module (M) for callbacks.
function M.render(M_CORE, opts, file, data_headers, data, metadata_headers, metadata_data)
	-- 1. Clean up old windows
	clear_main_handles() -- Use the new dedicated clear function

	local layout = opts.layout
	local width, height = vim.o.columns, vim.o.lines

	-- 2. Prepare Content (Assuming these are external helper functions)
	local help_lines = utils.prepare_help_display(layout)
	local metadata_lines = utils.prepare_metadata_display(file, metadata_headers, metadata_data)
	local data_lines = utils.format_data_table(data_headers, data)

	-- 3. Layout Calculations (Refactored for clarity)
	local height_help = 2
	local row_start = height_help + 3 -- Row where main windows begin

	-- Available height for metadata/data combined
	local available_height = height - row_start

	-- Initial height calculation
	local total_content_height = #metadata_lines + #data_lines
	local target_height_meta = math.floor(available_height * 0.4)
	local target_height_data = available_height - target_height_meta

	-- Constrain to content and ensure minimum size
	local metadata_height = math.max(4, math.min(#metadata_lines, target_height_meta))
	local data_height = math.max(8, math.min(#data_lines, target_height_data))

	-- Adjust heights if content is less than available
	if total_content_height < available_height then
		-- Distribute extra space if content is small, but keep the 40/60 ratio
		metadata_height = math.max(4, math.min(#metadata_lines, math.ceil(total_content_height * 0.4)))
		data_height = math.max(8, total_content_height - metadata_height)
	end

	-- Use fixed window margin
	local margin = math.floor(width * 0.01)
	local main_width = math.floor(width * 0.98)

	-- 4. Create windows (Helper window first)
	local buf_help, win_help = windows.create_floating_window({
		title = "Help",
		width = main_width,
		height = height_help,
		row = 1,
		col = margin,
	})

	local buf_meta, win_meta, buf_data, win_data, buf_sql, win_sql

	if layout == "vertical" then
		-- Vertical Layout
		buf_meta, win_meta = windows.create_floating_window({
			title = "Metadata",
			width = main_width,
			height = metadata_height,
			row = row_start,
			col = margin,
		})
		buf_data, win_data = windows.create_floating_window({
			title = "Data",
			width = main_width,
			height = data_height,
			row = row_start + metadata_height + 2, -- Directly stack them
			col = margin,
		})
	else -- horizontal
		-- Horizontal Layout
		local meta_width = math.floor(width * 0.35)
		local data_width = main_width - meta_width - margin -- Calculate remaining width

		local combined_height = metadata_height + data_height
		-- Ensure combined height doesn't exceed available_height, this is an
		-- approximation due to the prior calculations. Using available_height is safer.
		local height_combined = math.min(combined_height, available_height)

		buf_meta, win_meta = windows.create_floating_window({
			title = "Metadata",
			width = meta_width,
			height = height_combined,
			row = row_start,
			col = margin,
		})
		buf_data, win_data = windows.create_floating_window({
			title = "Data",
			width = data_width,
			height = height_combined,
			row = row_start,
			col = margin + meta_width + 1, -- Place next to metadata
		})
	end

	-- Windows for Query buf_sql
	buf_sql, win_sql = windows.create_floating_window({
		title = "Write SQL Query -- Ex: SELECT * FROM f WHERE ...",
		title_pos = "left",
		width = main_width,
		height = 5,
		row = 30,
		col = margin,
		hide = true,
		footer = "Press 'r' to toggle visibility",
	})

	-- 5. Cache handles (Using M.main_windows)
	M.main_windows = {
		buf_help = buf_help,
		win_help = win_help,
		buf_meta = buf_meta,
		win_meta = win_meta,
		buf_data = buf_data,
		win_data = win_data,
		buf_sql = buf_sql,
		win_sql = win_sql,
	}

	-- 6. Fill buffers (Optimized line setting)
	vim.api.nvim_buf_set_lines(buf_help, 0, -1, false, help_lines)
	vim.api.nvim_buf_set_lines(buf_meta, 0, -1, false, metadata_lines)
	vim.api.nvim_buf_set_lines(buf_data, 0, -1, false, data_lines)
	vim.api.nvim_buf_set_lines(buf_sql, 0, -1, false, { "-- Write SQL query here", "" })

	windows.focus_window(win_data)

	-- Set window options using helper function
	set_window_options({ win_meta, win_data, win_help, win_sql }, opts)

	-- 7. Setup Keymaps
	local function rotate_layout()
		-- Update the options table for the next call
		opts.layout = layout == "vertical" and "horizontal" or "vertical"
		-- Recurse to re-render with the new layout
		M.render(M_CORE, opts, file, data_headers, data, metadata_headers, metadata_data)
	end

	set_keymaps(M_CORE, opts, rotate_layout)
end

return M
