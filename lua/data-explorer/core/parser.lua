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
---@param csv_text string|nil: CSV text to parse.
---@param delim string: Delimiter used in the CSV (e.g., ",", "|").
---@return table|nil, string|nil: Parsed headers, data, and count of lines, or error message.
function M.parse_csv(csv_text, delim)
	if csv_text == nil or csv_text == "" then
		return nil, "CSV text is empty."
	end

	-- Clean newlines within quoted fields
	csv_text = clean_csv_newlines(csv_text)

	-- Split into lines
	local lines = vim.split(vim.trim(csv_text), "\n", { plain = true })

	-- Parse headers
	local headers = vim.split(lines[1], delim, { plain = true })
	local data = {}

	-- Parse data rows
	for i = 2, #lines do
		local values
		if delim == "," then
			values = split_csv_line(lines[i])
		else
			values = vim.split(lines[i], delim, { plain = true })
		end

		local row = {}
		for j, key in ipairs(headers) do
			row[key] = values[j] or ""
		end
		table.insert(data, row)
	end

	return { headers = headers, data = data }
end

--- Parse raw text out into structured table.
---@param raw_text string|nil: Raw text to parse.
---@return table|nil, string|nil: Parsed headers, data, and count of lines, or error message.
function M.parse_raw_text(raw_text)
	if raw_text == nil or raw_text == "" then
		return nil, "text is empty."
	end

	-- Split into lines
	local tbl_lines = {}
	for line in raw_text:gmatch("[^\r\n]+") do
		table.insert(tbl_lines, line)
	end

	-- Find count of lines
	local count_lines = 0
	for i, line in ipairs(tbl_lines) do
		if line:find("Count") then
			local data_line = tbl_lines[i + 3]
			if data_line then
				-- find the last field in the data_line
				local rev_fields = {}
				for field in data_line:gmatch("([^%s]+)") do
					table.insert(rev_fields, 1, field)
				end

				-- get the second field from the end
				local rev_field = rev_fields[2]
				if rev_field then
					local count_str = rev_field
					count_lines = tonumber(count_str) or 0
				end
			end
			break
		end
	end

	return { headers = {}, data = tbl_lines, count_lines = count_lines }
end

return M
