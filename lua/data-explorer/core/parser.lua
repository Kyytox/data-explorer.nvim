local log = require("data-explorer.gestion.log")
local M = {}

--- Clean newlines within quoted CSV fields.
---@param csv_text string: Original CSV text.
---@return string: Cleaned CSV text.
local function clean_csv_newlines(csv_text)
	local cleaned = csv_text:gsub('"(.-)"', function(field)
		field = field:gsub("[\r\n]+", " ")
		return '"' .. field .. '"'
	end)
	return cleaned
end

--- Parse CSV text into a structured table, handling quoted fields with newlines.
---@param csv_text string: CSV text to parse.
---@return table|nil, string|nil: Parsed headers, data, and count of lines, or error message.

function M.parse_csv(csv_text)
	-- Clean newlines within quoted fields
	csv_text = clean_csv_newlines(csv_text)

	-- Split into lines
	local lines = vim.split(vim.trim(csv_text), "\n", { plain = true })
	if #lines < 2 then
		return nil, "CSV data must have at least a header and one data row."
	end

	local headers = vim.split(lines[1], ",", { plain = true })
	local data = {}
	local count_lines = nil

	for i = 2, #lines do
		local values = vim.split(lines[i], ",", { plain = true })
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
