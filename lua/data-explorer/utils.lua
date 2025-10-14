local M = {}

--- Format data into a table with aligned columns.
---@param headers table: Column headers.
---@param data table: Table data.
---@return table: Formatted table lines.
function M.format_data_table(headers, data)
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

--- Prepare metadata display lines. (Moved from main module)
function M.prepare_metadata_display(file, metadata_headers, metadata_data)
	local tbl_metadata = M.format_data_table(metadata_headers, metadata_data)
	return {
		"📦 File: " .. vim.fn.fnamemodify(file, ":t"),
		"📂 Path: " .. file,
		"Number of lines: " .. tonumber(metadata_data[1]["Count"]),
		"",
		unpack(tbl_metadata),
	}
end

--- Prepare help display lines. (Moved from main module)
function M.prepare_help_display(layout)
	return {
		"layout: " .. layout,
		"q: quit  |  r: rotate layout  |  <bs>: back to file selection |  1: focus metadata  |  2: focus data",
	}
end

return M
