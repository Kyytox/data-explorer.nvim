local state = require("data-explorer.gestion.state")
local log = require("data-explorer.gestion.log")

local M = {}

local HISTORY = {}
local HISTORY_INDEX = 0

--- Load history from cache file
function M.load_history(history_file)
	local ok, history = pcall(dofile, history_file)
	if not ok then
		log.debug("Failed to load history cache file: ")
		return false
	end
	log.debug("Loaded history: " .. vim.inspect(history))
	HISTORY = history
	return true
end

--- Get history
---@return table: History table
function M.get_history()
	return HISTORY
end

--- Save history to cache file
function M.save_history()
	local dir_data = vim.fn.stdpath("data") .. state.get_variable("data_dir")
	local history_file = dir_data .. state.get_variable("history_cache")
	local file, err = io.open(history_file, "w")
	if not file then
		log.display_notify(3, "Failed to open history cache file for writing: " .. err)
		return
	end
	file:write("return " .. vim.inspect(HISTORY))
	file:close()
end

-- Add query to history
---@param query string: SQL query to add
function M.add_to_history(query, opts)
	table.insert(HISTORY, 1, query)

	-- Limit history size
	if #HISTORY > opts.query_sql.history_size then
		table.remove(HISTORY)
	end

	M.save_history()
end

--- Navigate history
---@param digit number: Positive for next, negative for previous
---@return string|nil: The query at the new index or nil if out of bounds
function M.navigate_history(digit)
	local new_index = HISTORY_INDEX + digit
	if new_index < 1 then
		new_index = #HISTORY
	elseif new_index > #HISTORY then
		new_index = 1
	end

	HISTORY_INDEX = new_index
	return HISTORY[new_index]
end

return M
