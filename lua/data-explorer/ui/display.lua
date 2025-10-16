local M = {}

--- Prepare metadata display lines. (Moved from main module)
---@param file string: File path.
---@param metadata table: Metadata table with headers and data.
---@return table: Lines to display.
function M.prepare_metadata(file, metadata)
	local tbl_metadata = M.prepare_data(metadata.headers, metadata.data)
	return {
		"📦 File: " .. vim.fn.fnamemodify(file, ":t"),
		"📂 Path: " .. file,
		"Number of lines: " .. tonumber(metadata.data[1]["Count"]),
		"",
		unpack(tbl_metadata),
	}
end

--- Prepare help display lines. (Moved from main module)
---@param opts table A table containing configuration, including command keybindings.
---@return table: Lines to display.
function M.prepare_help(opts)
	-- Use string.format to build the main help string
	local help_string = string.format(
		"%s: Quit | %s: Rotate | %s: SQL Query | %s: Back to file selection | %s: Focus metadata | %s: Focus data",
		opts.mappings.quit,
		opts.mappings.rotate_layout,
		opts.mappings.toggle_sql,
		opts.mappings.back,
		opts.mappings.focus_meta,
		opts.mappings.focus_data
	)

	return {
		help_string,
	}
end

--- Prepare SQL display
---@return table
function M.prepare_sql_display()
	return {
		-- "SELECT * FROM f;",
		-- "",
	}
end

--- Prepare SQL help display
---@param opts table A table containing configuration, including command keybindings.
---@return table
function M.prepare_sql_help(opts)
	-- Use string.format to build the SQL help string using the keybindings from 'keys'
	local help_string = string.format(
		"Ex: SELECT * FROM f WHERE ... | %s: Hide | %s: Execute",
		opts.mappings.toggle_sql,
		opts.mappings.execute_sql
	)
	return { help_string }
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
