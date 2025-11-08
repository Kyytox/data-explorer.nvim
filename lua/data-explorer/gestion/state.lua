local log = require("data-explorer.gestion.log")
local M = {}

local VARIABLES = {
	duckdb_cmd = "duckdb",
	data_dir = "/data_explorer/",
	duckdb_file = "data_explorer.db",
	windows_infos = {
		meta_title = " Metadata ",
		data_title = " Data View - Page 1 ",
		sql_title = " SQL Query ",
		sql_err_title = " SQL Error ",
	},
}

-- Get specific variable
function M.get_variable(field)
	return VARIABLES[field]
end

local STATE = {
	files_metadata = {},
	buffers = {},
	windows = {},
	current_file = nil,
	current_layout = nil,
	tbl_dimensions = {},
	num_page = 1,
	last_user_query = nil,
}

-- Get all state
function M.get_all_state()
	return STATE
end

-- Set state value
---@param field string: STATE field name
---@param key any: Key for the field table (or nil for direct value)
---@param value any: Value to set
function M.set_state(field, key, value)
	if key ~= nil then
		STATE[field][key] = value
	else
		STATE[field] = value
	end
end

-- Get state value
---@param field string: STATE field name
---@param key any|nil: Key for the field table (optional)
---@return any
function M.get_state(field, key)
	if key ~= nil then
		if STATE[field] == nil then
			return nil
		end
		return STATE[field][key]
	end
	return STATE[field]
end

-- Reset one or all state fields
---@param field string|nil: STATE field name (optional)
function M.reset_state(field)
	if field and STATE[field] then
		STATE[field] = {}
	else
		for k, _ in pairs(STATE) do
			STATE[k] = {}
		end
	end
end

return M
