local M = {}

--- Prepare metadata display lines.
---@param file string: File path.
---@param metadata table: Metadata table with headers and data.
---@return table: Lines to display.
function M.prepare_metadata(file, metadata)
	local tbl_metadata = M.prepare_data(metadata.headers, metadata.data)
	return {
		"📦 File: " .. vim.fn.fnamemodify(file, ":t"),
		"📂 Path: " .. file,
		"Number of lines: " .. tonumber(metadata.count_lines),
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
			"%s: Quit | %s: Rotate | %s: Back file selection | %s: SQL Query | %s: Metadata | %s: Data",
			opts.mappings.quit,
			opts.mappings.rotate_layout,
			opts.mappings.back,
			opts.mappings.toggle_sql,
			opts.mappings.focus_meta,
			opts.mappings.focus_data
		),
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

--- Format data into a table with aligned columns.
---@param headers table: Column headers.
---@param data table: Table data.
---@return table: Formatted table lines.
function M.prepare_data(headers, data)
	local col_widths = {}

	for _, h in ipairs(headers) do
		col_widths[h] = #h
	end

	for _, row in ipairs(data) do
		for _, h in ipairs(headers) do
			local val = row[h] or ""
			if #val > col_widths[h] then
				col_widths[h] = #val
			end
		end
	end

	for k, w in pairs(col_widths) do
		col_widths[k] = w + 1 -- padding
	end

	local function pad(str, width)
		return str .. string.rep(" ", width - #str)
	end

	local header_line = table.concat(
		vim.tbl_map(function(h)
			return pad(h, col_widths[h])
		end, headers),
		"│"
	)

	local separator = table.concat(
		vim.tbl_map(function(h)
			return string.rep("─", col_widths[h])
		end, headers),
		"┼"
	)

	local tbl_lines = { header_line, separator }
	for _, row in ipairs(data) do
		local parts = {}
		for _, h in ipairs(headers) do
			table.insert(parts, pad(row[h] or "", col_widths[h]))
		end
		table.insert(tbl_lines, table.concat(parts, "│"))
	end

	return tbl_lines
end

return M
