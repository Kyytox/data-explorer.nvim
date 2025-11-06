local log = require("data-explorer.gestion.log")
local M = {}

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
