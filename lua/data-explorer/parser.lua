local log = require("data-explorer.log")
local M = {}

--- Parse CSV text into a structured table.
---@param csv_text string: CSV text to parse.
---@return table|nil, table|nil, string|nil: Parsed headers, data, and count of lines, or error message.
function M.parse_csv(csv_text)
	local lines = vim.split(vim.trim(csv_text), "\n", { plain = true })
	if #lines < 2 then
		return nil, nil, nil
	end

	local count_lines = nil
	local headers = vim.split(lines[1], ",", { plain = true })
	local data = {}

	for i = 2, #lines do
		local values = vim.split(lines[i], ",", { plain = true })
		local row = {}
		for j, key in ipairs(headers) do
			if key == "Count" then
				count_lines = vim.trim(values[j]) or "0"
			else
				row[key] = vim.trim(values[j]) or ""
			end
		end

		table.insert(data, row)
	end

	-- Remove Count from headers if present
	for i, header in ipairs(headers) do
		if header == "Count" then
			table.remove(headers, i)
			break
		end
	end
	log.info(tostring(vim.inspect(count_lines)))

	return { headers = headers, data = data, count_lines = count_lines }
end

--- Parse the 'Columns' string from CSV/TSV metadata into a structured table.
---@param input string: The raw 'Columns' string from DuckDB.
---@return table|nil, table|nil, string|nil: Parsed headers, data, and count of lines, or error message.
function M.parse_columns_string(input)
	-- Get Count of lines (last elemtnt after spli t by ,)
	local parts = vim.split(input, ",")
	local count_lines = parts[#parts]:gsub("[\r\n]+", "")

	-- Extract the JSON-like substring
	local text = input:match('"(.+)"')
	if not text then
		vim.notify("No valid Columns string found.", vim.log.levels.ERROR)
		return nil, nil
	end

	-- Transform to valid JSON
	text = text:gsub("'", '"')

	-- Quote the keys
	text = text:gsub("(%w+)%s*:", '"%1":')

	-- Ensure that unquoted values are quoted (for 'name' and 'type' fields)
	text = text:gsub(":(%s*)([%w_]+)", ': "%2"')

	-- Decode the JSON string
	local ok, decoded = pcall(vim.fn.json_decode, text)
	if not ok then
		vim.notify("Failed to decode Columns string: " .. decoded, vim.log.levels.ERROR)
		return nil, nil
	end

	-- Transform into structured table
	local parsed_headers = { "column", "type" }
	local parsed_data = {}

	for _, col in ipairs(decoded) do
		table.insert(parsed_data, {
			column = col.name,
			type = col.type,
		})
	end

	return { headers = parsed_headers, data = parsed_data, count_lines = count_lines }
end

return M
