local log = require("data-explorer.gestion.log")
local M = {}

--- Prepare metadata display lines.
---@param file string: File path.
---@param metadata table: Metadata table with headers and data.
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

--- Prepare help display lines.
---@param opts table A table containing configuration, including command keybindings.
---@return table: Lines to display.
function M.prepare_help(opts)
	return {
		string.format(
			" %s: Quit | %s: Rotate | %s: Back file selection | %s: Metadata | %s: Data | %s: SQL Query ",
			opts.mappings.quit,
			opts.mappings.rotate_layout,
			opts.mappings.back,
			opts.mappings.focus_meta,
			opts.mappings.focus_data,
			opts.mappings.toggle_sql
		),
	}
end

--- Prepare SQL display
---@param opts table A table containing configuration, including command keybindings.
---@return table
function M.prepare_sql_display(opts)
	return {
		"SELECT * FROM f LIMIT 1000;",
		"-- Warning: Large result could slow down / crash Neovim.",
	}
end

--- Prepare SQL help display
---@param opts table A table containing configuration, including command keybindings.
---@return table
function M.prepare_sql_help(opts)
	return {
		string.format(
			"Ex: SELECT * FROM f WHERE ... | %s: Hide | %s: Execute",
			opts.mappings.toggle_sql,
			opts.mappings.execute_sql
		),
	}
end

--- Prepare table data for display.
--- Formats headers and data into aligned table lines.
---@param headers table: Column headers.
---@param data table: Table data.
---@return table: Formatted table lines.
function M.prepare_data(headers, data)
	local col_widths = {}

	-- Determine maximum width for each column
	for _, h in ipairs(headers) do
		col_widths[h] = #h
	end
	for _, row in ipairs(data) do
		for _, h in ipairs(headers) do
			local val = tostring(row[h] or "")
			if #val > col_widths[h] then
				col_widths[h] = #val
			end
		end
	end

	-- Add padding + apply maximum width limit
	for k, w in pairs(col_widths) do
		col_widths[k] = w + 1
	end

	-- Helper: pad and trim string
	local function pad_right(str, width)
		local truncated = str
		if #truncated > width - 1 then
			truncated = truncated:sub(1, width - 1)
		end
		return truncated .. string.rep(" ", width - #truncated)
	end

	-- Build header line
	local header_line = table.concat(
		vim.tbl_map(function(h)
			return pad_right(h, col_widths[h])
		end, headers),
		"│"
	)

	-- Separator line
	local separator = table.concat(
		vim.tbl_map(function(h)
			return string.rep("─", col_widths[h])
		end, headers),
		"┼"
	)

	-- Table body
	local tbl_lines = { header_line, separator }
	for _, row in ipairs(data) do
		local parts = {}
		for _, h in ipairs(headers) do
			local val = tostring(row[h] or " ")
			table.insert(parts, pad_right(val, col_widths[h]))
		end
		table.insert(tbl_lines, table.concat(parts, "│"))
	end

	return tbl_lines
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

--- Update highlights in buffers using extmarks
---@param buf number: Buffer number.
---@param data_lines table: Lines of data in the buffer.
---@return nil
function M.update_highlights(buf, data_lines)
	-- Create a namespace for highlights
	local ns_id = vim.api.nvim_create_namespace("data_explorer_highlight_namespace")

	-- Browse header line for find all | and create table
	local header_line = data_lines[1]
	local tbl_pos = {}
	local col_start = 0
	local col_index = 1
	while true do
		-- Find next |
		local s, e = string.find(header_line, "│", col_start + 1, true)
		if not s then
			break
		end

		-- Store column positions
		tbl_pos[col_index] = { col_index = col_index, start = col_start, finish = s - 1 }
		col_index = col_index + 1
		col_start = e
	end

	-- Browse lines and highlight based on tbl_pos
	for l = 1, #data_lines do
		for _, col in pairs(tbl_pos) do
			local value_start = col.start + 1
			local value_end = col.finish
			local hl_group = ""

			if l ~= 2 then -- Skip separator line
				-- Find highlight group
				hl_group = determine_hl_group(l, col.col_index)

				-- Set extmark for highlight
				vim.api.nvim_buf_set_extmark(buf, ns_id, l - 1, value_start - 1, {
					end_col = value_end - 1,
					hl_group = hl_group,
				})
			end
		end
	end
end

return M
