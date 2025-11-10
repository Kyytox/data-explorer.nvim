local duckdb = require("data-explorer.core.duckdb")
local state = require("data-explorer.gestion.state")
local log = require("data-explorer.gestion.log")
local actions_history = require("data-explorer.actions.actions_history")

local M = {}

---Create cache files for process
function M.create_cache_files(opts)
	local dir_data = vim.fn.stdpath("cache") .. state.get_variable("data_dir")

	if vim.fn.isdirectory(dir_data) == 0 then
		vim.fn.mkdir(dir_data, "p")
	end

	-- Create history file (lua file)
	local history_file = dir_data .. state.get_variable("history_cache")
	if not actions_history.load_history(history_file) then
		-- Create empty history file
		local file, err = io.open(history_file, "w")
		if not file then
			log.display_notify(3, "Failed to create history cache file: " .. err)
			return
		end
		file:write("return {}")
		file:close()
	end
end

--- Check if file is a accepted file type
---@param file string: File path.
---@param accepted_types table: List of accepted file extensions.
---@return boolean: True if is accepted, false otherwise.
function M.is_accepted_file_type(file, accepted_types)
	for _, ext in ipairs(accepted_types) do
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

	-- for _, f in ipairs(opts.exclude_files or {}) do
	-- 	table.insert(cmd, "--exclude")
	-- 	table.insert(cmd, f)
	-- end

	return cmd
end

--- Get file size, determine KB or MB.
---@param file string: File path.
---@return string: Size in KB or MB.
local function get_file_size_mb(file)
	local size = 0
	local ext = " KB"
	local f = io.open(file, "r")
	if f then
		local file_size = f:seek("end")
		size = math.floor(file_size / 1024) -- size in KB

		-- Convert to MB if larger than 1024 KB
		if size >= 1024 then
			size = math.floor(size / 1024) + 1 -- size in MB
			ext = " MB"
		end
		f:close()
	end
	return tostring(size) .. ext
end

--- Get cached metadata if available, otherwise fetch and cache it.
---@param file string: File path.
---@return table|nil: Metadata table or nil if error occurs.
---@return string|nil: Error message if any.
function M.get_cached_metadata(file)
	local err = nil
	local metadata = state.get_state("files_metadata", file) or nil

	if metadata then
		return metadata, nil
	end

	-- Get file size in MB
	local size = get_file_size_mb(file)

	-- exrtact file extensions
	local ext = file:match("^.+(%..+)$"):sub(2)

	-- Fetch and parse metadata
	metadata, err = duckdb.fetch_metadata(file, ext)
	if not metadata then
		return nil, err
	end

	-- Add file size and extension
	metadata.file_size = size
	metadata.file_ext = ext

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
