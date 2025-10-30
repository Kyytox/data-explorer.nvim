local Path = require("plenary.path")
local duckdb = require("data-explorer.core.duckdb")
local state = require("data-explorer.gestion.state")
local log = require("data-explorer.gestion.log")

local M = {}

--- Check if file is a accepted file type
---@param file string: File path.
---@param accepted_types table: List of accepted file extensions.
---@return boolean: True if file is accepted, false otherwise.
function M.is_accepted_file_type(file, accepted_types)
	for _, ext in ipairs(accepted_types) do
		-- Use string.sub for cleaner suffix check
		if file:sub(-#ext) == ext then
			return true
		end
	end
	return false
end

--- Build the fd/fdfind command for finding files.
---@param extensions table: List of file extensions to include.
---@param opts table: Options including include_hidden, exclude_dirs, exclude_files.
---@return table: Command as a list of strings.
function M.build_fd_command(extensions, opts)
	local fd_cmd
	if vim.fn.executable("fd") == 1 then
		fd_cmd = "fd"
	elseif vim.fn.executable("fdfind") == 1 then
		fd_cmd = "fdfind"
	else
		log.display_notify(4, "fd or fdfind is not installed or not in PATH")
		return {}
	end

	local cmd = { fd_cmd, "--type", "f" }

	if opts.include_hidden then
		table.insert(cmd, "--hidden")
	end

	for _, ext in ipairs(extensions or {}) do
		table.insert(cmd, "--extension")
		table.insert(cmd, ext)
	end

	for _, dir in ipairs(opts.exclude_dirs or {}) do
		table.insert(cmd, "--exclude")
		table.insert(cmd, dir)
	end

	for _, f in ipairs(opts.exclude_files or {}) do
		table.insert(cmd, "--exclude")
		table.insert(cmd, f)
	end

	return cmd
end

--- Get metadata and cache it
---@param file string: File path.
---@return table|nil: Metadata table or nil if error occurs.
---@return string|nil: Error message if any.
function M.get_cached_metadata(file)
	-- Check cache first
	local metadata = state.get_state("files_metadata", file)

	if metadata then
		return metadata, nil
	end

	-- Fetch and parse metadata
	metadata, err = duckdb.fetch_parse_data(file, "metadata", nil, nil)
	if not metadata then
		return nil, err
	end

	-- Set Cache metadata
	state.set_state("files_metadata", file, metadata)
	return metadata, nil
end

--- Aggragate files types
---@param opts table: Configuration options.
---@return table: List of file types.
function M.aggregate_file_types(opts)
	local files_types = opts.files_types
	local file_types_list = {}

	for key, top in pairs(files_types) do
		if top then
			table.insert(file_types_list, key)
		end
	end

	return file_types_list
end

return M
