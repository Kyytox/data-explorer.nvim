local log = require("data-explorer.gestion.log")

local M = {}

--- Ensure limit is a positive number
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.check_limit(defaults, opts)
	if type(opts.limit) ~= "number" or opts.limit <= 0 then
		opts.limit = defaults.limit
		return "limit must be a positive number. Reverting to default."
	end
end

--- Ensure Layout is valid
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.check_layout(defaults, opts)
	if opts.layout ~= "vertical" and opts.layout ~= "horizontal" then
		opts.layout = defaults.layout
		return 'layout must be "vertical" or "horizontal". Reverting to default.'
	end
end

--- Ensure placeholder_sql is a table
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.check_placeholder_sql(defaults, opts)
	if type(opts.query_sql.placeholder_sql) ~= "table" then
		opts.query_sql.placeholder_sql = defaults.query_sql.placeholder_sql
		return "placeholder_sql must be a table. Reverting to default."
	end
end

--- Ensure max_height_metadata and max_width_metadata are numbers between 0 and 1
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.check_max_metadata_dimensions(defaults, opts)
	local max_height = opts.window_opts.max_height_metadata
	local max_width = opts.window_opts.max_width_metadata
	if
		(type(max_height) ~= "number" or max_height <= 0 or max_height >= 1)
		or (type(max_width) ~= "number" or max_width <= 0 or max_width >= 1)
	then
		opts.window_opts.max_height_metadata = defaults.window_opts.max_height_metadata
		opts.window_opts.max_width_metadata = defaults.window_opts.max_width_metadata
		return "max_height_metadata and max_width_metadata must be numbers between 0 and 1. Reverting to default.."
	end
end

--- Ensure files_types is a table and has accepted types
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.check_files_types(defaults, opts)
	if type(opts.files_types) ~= "table" then
		opts.files_types = defaults.files_types
		return "files_types must be a table. Reverting to default."
	end

	local accepted_types = defaults.files_types
	local filtered_types = {}
	local success = true
	local fail_key = {}
	for key, value in pairs(opts.files_types) do
		if accepted_types[key] and value == true then
			filtered_types[key] = true
		elseif not accepted_types[key] and value == true then
			filtered_types[key] = false
			success = false
			table.insert(fail_key, key)
		end
	end
	opts.files_types = filtered_types
	if not success then
		return "Unsupported file type: "
			.. table.concat(fail_key, ", ")
			.. ". \nSupported types are: "
			.. table.concat(vim.tbl_keys(accepted_types), ", ")
			.. "."
			.. "\nTypes not supported have been disabled."
	end
end

--- Ensure exclude_dirs is a table
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.check_exclude_dirs(defaults, opts)
	if type(opts.telescope_opts.finder.exclude_dirs) ~= "table" then
		opts.telescope_opts.finder.exclude_dirs = defaults.telescope_opts.finder.exclude_dirs
		return "exclude_dirs must be a table. Reverting to default."
	end
end

--- Ensure mappings is a table, where all values are strings
---@param defaults table -- Default configuration options.
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.check_mappings(defaults, opts)
	if type(opts.mappings) ~= "table" then
		opts.mappings = defaults.mappings
		return "mappings must be a table. Reverting to default."
	end

	for key, value in pairs(opts.mappings) do
		if type(value) ~= "string" then
			opts.mappings[key] = defaults.mappings[key]
			return "Mapping for " .. key .. " must be a string. Reverting to default."
		end
	end
end

-- Check for valid options
--- Validate user-provided options and revert to defaults. if invalid.
---@param opts table -- User-provided options.
---@return string|nil -- Error message if validation fails, nil otherwise.
function M.validate_options(defaults, opts)
	local error_msg

	local checks = {
		M.check_limit,
		M.check_layout,
		M.check_placeholder_sql,
		M.check_max_metadata_dimensions,
		M.check_files_types,
		M.check_exclude_dirs,
	}

	for _, check in ipairs(checks) do
		error_msg = check(defaults, opts)
		if error_msg then
			log.display_notify(3, error_msg)
		end
	end
end

return M
