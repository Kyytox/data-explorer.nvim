local log = require("data-explorer.gestion.log")
local M = {}

--- Parse CSV text into a structured table.
---@param csv_text string: CSV text to parse.
---@return table|nil, string|nil: Parsed headers, data, and count of lines, or error message.
function M.parse_csv(csv_text)
	local lines = vim.split(vim.trim(csv_text), "\n", { plain = true })
	if #lines < 2 then
		return nil, "CSV data must have at least a header and one data row."
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
				row[key] = values[j] or ""
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

	return { headers = headers, data = data, count_lines = count_lines }
end

return M
