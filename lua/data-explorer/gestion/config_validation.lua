local log = require("data-explorer.gestion.log")

local M = {}
M.user_opts = {}

local function check_number(opts, key)
	if type(opts[key]) ~= "number" or opts[key] <= 0 then
		return false
	end
	return true
end

local function check_string(opts, key)
	if type(opts[key]) ~= "string" then
		return false
	end
	return true
end

local function check_boolean(opts, key)
	if type(opts[key]) ~= "boolean" then
		return false
	end
	return true
end

local function check_table(opts, key)
	if type(opts[key]) ~= "table" then
		return false
	end
	return true
end

---@param defaults table Default configuration options.
---@param opts table User-provided options.
---@param key string Key to validate.
---@return table: List of error messages if validation fails.
function M.check_limit(defaults, opts, key)
	if not check_number(opts, key) then
		opts[key] = defaults[key]
		return { "limit must be a positive number. Reverting to default." }
	end
	return {}
end

---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@param key string: Key to validate.
---@return table: List of error messages if validation fails.
function M.check_layout(defaults, opts, key)
	if opts[key] ~= "vertical" and opts[key] ~= "horizontal" then
		opts[key] = defaults[key]
		return { 'layout must be "vertical" or "horizontal". Reverting to default.' }
	end
	return {}
end

---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@param key string: Key to validate.
---@return table: List of error messages if validation fails.
function M.check_query_sql(defaults, opts, key)
	local errs = {}

	if not check_table(opts, key) then
		opts[key] = defaults[key]
		table.insert(errs, "query_sql must be a table. Reverting to default.")
	end

	if not check_table(opts[key], "placeholder_sql") then
		opts[key].placeholder_sql = defaults[key].placeholder_sql
		table.insert(errs, "placeholder_sql must be a table. Reverting to default.")
	end
	return errs
end

---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@param key string: Key to validate.
---@return table: List of error messages if validation fails.
function M.check_files_types(defaults, opts, key)
	local errs = {}

	if not check_table(opts, key) then
		opts[key] = defaults[key]
		table.insert(errs, key .. " must be a table. Reverting to default.")
	end

	local accepted_types = defaults[key]
	local filtered_types = {}
	local success = true
	local fail_key = {}
	for sub_key, value in pairs(opts[key]) do
		if accepted_types[sub_key] and value == true then -- accepted and enabled
			filtered_types[sub_key] = true
		elseif accepted_types[sub_key] and value == false then -- accepted but disabled
			filtered_types[sub_key] = false
		elseif not accepted_types[sub_key] and value == true then -- not accepted but enabled
			filtered_types[sub_key] = false
			success = false
			table.insert(fail_key, sub_key)
		end
	end

	opts[key] = filtered_types
	if not success then
		table.insert(
			errs,
			"Unsupported file type: "
				.. table.concat(fail_key, ", ")
				.. ". \nSupported types are: "
				.. table.concat(vim.tbl_keys(accepted_types), ", ")
				.. "."
				.. "\nTypes not supported have been disabled."
		)
	end

	return errs
end

---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@param key string: Key to validate.
---@return table: List of error messages if validation fails.
function M.check_telescope_opts(defaults, opts, key)
	local errs = {}

	if not check_table(opts, key) then
		opts[key] = defaults[key]
		table.insert(errs, key .. " must be a table. Reverting to default.")
	end

	if not check_string(opts[key], "layout_strategy") then
		opts[key].layout_strategy = defaults[key].layout_strategy
		table.insert(errs, "layout_strategy must be a string. Reverting to default.")
	end

	if not check_boolean(opts[key].finder, "include_hidden") then
		opts[key].finder.include_hidden = defaults[key].finder.include_hidden
		table.insert(errs, "include_hidden must be a boolean. Reverting to default.")
	end

	if not check_table(opts[key].finder, "exclude_dirs") then
		opts[key].finder.exclude_dirs = defaults[key].finder.exclude_dirs
		table.insert(errs, "exclude_dirs must be a table. Reverting to default.")
	end

	for sub_key, value in pairs(opts[key].layout_config) do
		if type(value) == "number" then
			if sub_key == "preview_cutoff" then
				if value < 0 then
					opts[key].layout_config[sub_key] = defaults[key].layout_config[sub_key]
					table.insert(errs, sub_key .. " must be a non-negative number. Reverting to default.")
				end
			else
				if value <= 0 or value > 1 then
					opts[key].layout_config[sub_key] = defaults[key].layout_config[sub_key]
					table.insert(errs, sub_key .. " must be a number between 0 and 1. Reverting to default.")
				end
			end
		else
			opts[key].layout_config[sub_key] = defaults[key].layout_config[sub_key]
			table.insert(errs, sub_key .. " must be a number. Reverting to default.")
		end
	end
	return errs
end

---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@param key string: Key to validate.
---@return table: List of error messages if validation fails.
function M.check_window_opts(defaults, opts, key)
	local errs = {}

	if not check_table(opts, key) then
		opts[key] = defaults[key]
		table.insert(errs, "window_opts must be a table. Reverting to default.")
	end

	local max_height = opts[key].max_height_metadata
	local max_width = opts[key].max_width_metadata
	if
		(type(max_height) ~= "number" or max_height <= 0 or max_height >= 1)
		or (type(max_width) ~= "number" or max_width <= 0 or max_width >= 1)
	then
		opts[key].max_height_metadata = defaults[key].max_height_metadata
		opts[key].max_width_metadata = defaults[key].max_width_metadata
		table.insert(
			errs,
			"max_height_metadata and max_width_metadata must be numbers between 0 and 1. Reverting to default."
		)
	end

	if not check_string(opts[key], "border") then
		opts[key].border = defaults[key].border
		table.insert(errs, "border must be a string. Reverting to default.")
	end

	return errs
end

---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@param key string: Key to validate.
---@return table: List of error messages if validation fails.
function M.check_mappings(defaults, opts, key)
	local errs = {}

	if not check_table(opts, key) then
		opts[key] = defaults[key]
		table.insert(errs, "mappings must be a table. Reverting to default.")
	end

	for sub_key, value in pairs(opts[key]) do
		if type(value) ~= "string" then
			opts[key][sub_key] = defaults[key][sub_key]
			table.insert(errs, "Mapping for " .. sub_key .. " must be a string. Reverting to default.")
		end
	end
	return errs
end

---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@param key string: Key to validate.
---@return table: List of error messages if validation fails.
function M.check_highlight(defaults, opts, key)
	local errs = {}

	-- if type(opts[key]) ~= "table" then
	if not check_table(opts, key) then
		opts[key] = defaults[key]
		table.insert(errs, "hl must be a table. Reverting to default.")
	end

	if not check_table(opts[key], "windows") then
		opts[key].windows = defaults[key].windows
		table.insert(errs, "hl.windows must be a table. Reverting to default.")
	end

	for sub_key, value in pairs(opts[key].windows) do
		if not check_string(opts[key].windows, sub_key) then
			opts[key].windows[sub_key] = defaults[key].windows[sub_key]
			table.insert(errs, "hl.windows." .. sub_key .. " must be a string. Reverting to default.")
		end
	end

	if not check_table(opts[key], "buffer") then
		opts[key].buffer = defaults[key].buffer
		table.insert(errs, "hl.buffers must be a table. Reverting to default.")
	end

	for sub_key, value in pairs(opts[key].buffer) do
		if sub_key == "hl_enable" then
			if not check_boolean(opts[key].buffer, sub_key) then
				opts[key].buffer[sub_key] = defaults[key].buffer[sub_key]
				table.insert(errs, "hl.buffers." .. sub_key .. " must be a boolean. Reverting to default.")
			end
		elseif not check_string(opts[key].buffer, sub_key) then
			opts[key].buffer[sub_key] = defaults[key].buffer[sub_key]
			table.insert(errs, "hl.buffers." .. sub_key .. " must be a string. Reverting to default.")
		end
	end
	return errs
end

--- Valid user options and revert to defaults. if invalid.
---@param defaults table: Default configuration options.
---@param opts table: User-provided options.
---@return table: Validated user options.
function M.valid_user_options(defaults, opts)
	local error_msg
	M.user_opts = opts or {}

	local checks = {
		limit = M.check_limit,
		layout = M.check_layout,
		files_types = M.check_files_types,
		telescope_opts = M.check_telescope_opts,
		window_opts = M.check_window_opts,
		query_sql = M.check_query_sql,
		mappings = M.check_mappings,
		hl = M.check_highlight,
	}

	-- Execute specific check when key is provided
	for key, check_func in pairs(checks) do
		if opts[key] ~= nil then
			error_msg = check_func(defaults, M.user_opts, key)
			if #error_msg > 0 then
				for _, msg in ipairs(error_msg) do
					log.display_notify(3, msg)
				end
			end
		end
	end
	return M.user_opts
end

return M
