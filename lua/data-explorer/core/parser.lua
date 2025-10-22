local log = require("data-explorer.gestion.log")
local M = {}

--- Clean newlines within quoted CSV fields.
---@param csv_text string: Original CSV text.
---@return string: Cleaned CSV text.
local function clean_csv_newlines(csv_text)
	local cleaned = csv_text:gsub('"(.-)"', function(field)
		field = field:gsub("[\r\n]+", "")
		return '"' .. field .. '"'
	end)
	return cleaned
end

--- Split a CSV line on commas outside of quotes.
---@param line string: CSV line to split.
---@return table: List of fields.
local function split_csv_line(line)
	local res = {}
	local i = 1
	local len = #line
	local in_quotes = false
	local field_start = 1

	while i <= len do
		local c = line:sub(i, i)
		if c == '"' then
			-- toggle quotes unless it's a doubled quote ("")
			if line:sub(i + 1, i + 1) == '"' then
				i = i + 1 -- skip escaped quote
			else
				in_quotes = not in_quotes
			end
		elseif c == "," and not in_quotes then
			-- extract field
			local field = line:sub(field_start, i - 1):gsub('^"', ""):gsub('"$', "")
			table.insert(res, field)
			field_start = i + 1
		end
		i = i + 1
	end

	-- last field
	local field = line:sub(field_start):gsub('^"', ""):gsub('"$', "")
	table.insert(res, field)
	return res
end

--- Parse CSV text into a structured table, handling quoted fields with newlines.
---@param csv_text string: CSV text to parse.
---@return table|nil, string|nil: Parsed headers, data, and count of lines, or error message.
function M.parse_csv(csv_text, tt)
	-- Clean newlines within quoted fields
	csv_text = clean_csv_newlines(csv_text)
	log.debug("Cleaned CSV")

	-- Split into lines
	local lines = vim.split(vim.trim(csv_text), "\n", { plain = true })
	if #lines < 2 then
		return nil, "CSV data must have at least a header and one data row."
	end

	-- Parse headers
	local headers = vim.split(lines[1], tt, { plain = true })
	local data = {}
	local count_lines = nil

	-- Parse data rows
	for i = 2, #lines do
		local values
		if tt == "," then
			values = split_csv_line(lines[i])
		else
			values = vim.split(lines[i], tt, { plain = true })
		end
		local row = {}
		for j, key in ipairs(headers) do
			if key == "Count" then
				count_lines = vim.trim(values[j]) or "0"
			else
				row[key] = values[j] or ""
			end
		end
		table.insert(data, row)
	end

	-- remove Count from headers if present
	for i, header in ipairs(headers) do
		if header == "Count" then
			table.remove(headers, i)
			break
		end
	end

	return { headers = headers, data = data, count_lines = count_lines }
end

return M
