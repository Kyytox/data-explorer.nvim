local M = {}

--- Prepare metadata display lines.
---@param file string: File path.
---@param metadata table: Metadata table with headers and data.
---@return table: Lines to display.
function M.prepare_metadata(file, metadata)
	if tonumber(metadata.count_lines) == 0 then
		return {
			file,
			"",
			"",
			"No data in the file.",
		}
	end

	local tbl_metadata = M.prepare_data(metadata.headers, metadata.data)
	return {
		file,
		"Number of lines: " .. tonumber(metadata.count_lines),
		"File size (KB): " .. tostring(metadata.file_size),
		"",
		unpack(tbl_metadata),
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

return M
