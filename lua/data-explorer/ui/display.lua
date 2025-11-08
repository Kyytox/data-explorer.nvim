local M = {}

--- Prepare metadata display lines.
---@param file string: File path.
---@param metadata table: Metadata infos.
---@return table: Lines to display.
function M.prepare_metadata(file, metadata)
	if metadata.count_lines == 0 then
		return {
			file,
			"",
			"",
			"No data in the file.",
		}
	end

	return {
		file,
		"File size: " .. tostring(metadata.file_size),
		"Number of lines: " .. tonumber(metadata.count_lines),
		"",
		unpack(metadata.data),
	}
end

--- Prepare footer help
---@param opts table Condiguration options including key mappings.
---@return table: Lines to display.
function M.prepare_help(opts)
	return {
		string.format(
			" %s: Quit | %s: Rotate | %s: Next Page | %s: Prev Page | %s: Metadata | %s: Data | %s: SQL Query | %s: Back ",
			opts.mappings.quit,
			opts.mappings.rotate_layout,
			opts.mappings.next_page,
			opts.mappings.prev_page,
			opts.mappings.focus_meta,
			opts.mappings.focus_data,
			opts.mappings.toggle_sql,
			opts.mappings.back
		),
	}
end

--- Prepare SQL footer Help display
---@param opts table A table containing configuration, including command keybindings.
---@return table
function M.prepare_sql_help(opts)
	return {
		string.format(
			" %s - %s: Navigate History | %s: Execute Query ",
			opts.mappings.prev_history,
			opts.mappings.next_history,
			opts.mappings.execute_sql
		),
	}
end

--- Determine highlight group based on column index
---@param line number: Line number in the buffer.
---@param col_index number: Column index.
---@return string: Highlight group name.
local function determine_hl_group(line, col_index)
	if line == 1 then
		return "DataExplorerColHeader"
	else
		local y = col_index % 9
		if y == 0 then
			y = 9
		end
		local hl_group = "DataExplorerCol" .. tostring(y)
		return hl_group
	end
end

--- Update highlights in buffers
---@param buf number: Buffer number.
---@param data_lines table: Lines of data in the buffer.
function M.update_highlights(buf, data_lines)
	-- Create a namespace for highlights
	local ns_id = vim.api.nvim_create_namespace("data_explorer_highlight_ns")

	-- Calculate column positions, and their highlight groups
	local header_line = data_lines[2]
	local tbl_pos = {}
	local col_start = 4
	local col_index = 1
	local hl_group
	while true do
		-- Find start and end of column
		local st, ed = string.find(header_line, "│", col_start + 1, true)
		if not st then
			break
		end

		-- Find highlight group
		hl_group = determine_hl_group(2, col_index)

		-- Store column positions
		tbl_pos[col_index] = { col_index = col_index, start = col_start, finish = st - 1, hl_group = hl_group }
		col_index = col_index + 1
		col_start = ed
	end

	-- Browse lines and highlight based on tbl_pos
	local lines_footer = 1
	if #data_lines <= 6 then
		lines_footer = 3
	elseif #data_lines >= 14 then
		lines_footer = 3
	end

	for l = 1, #data_lines - lines_footer do
		for _, col in pairs(tbl_pos) do
			local value_start = col.start + 1
			local value_end = col.finish

			if l > 4 then -- Skip separator line
				-- Set extmark for highligh
				vim.api.nvim_buf_set_extmark(buf, ns_id, l - 1, value_start - 1, {
					end_col = value_end,
					hl_group = col.hl_group,
				})
			else
				-- Header line
				hl_group = determine_hl_group(1, col.col_index)
				vim.api.nvim_buf_set_extmark(buf, ns_id, l - 1, value_start - 1, {
					end_col = value_end,
					hl_group = hl_group,
				})
			end
		end
	end
end

return M
