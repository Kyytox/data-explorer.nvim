local Path = require("plenary.path")
local duckdb = require("data-explorer.core.duckdb")
local state = require("data-explorer.gestion.state")

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

--- Build the glob pattern string from a list of extensions.
--- @param files_types table: List of accepted file extensions (e.g., {".csv", ".parquet"}).
--- @return string: The glob pattern string (e.g., "{.csv,.parquet}").
local function build_glob_pattern(files_types)
	-- Remove the leading dot for globbing, though it works with or without it in vim.fn.glob
	local patterns = vim.tbl_map(function(ext)
		return "*" .. ext -- e.g., "*.parquet"
	end, files_types)

	-- Join them into a format like "*.{parquet,csv}" for shell globbing
	return "*{" .. table.concat(patterns, ",") .. "}"
end

--- Get all files in working directory
---@param files_types table: List of accepted file extensions.
---@return table: List of file paths.
function M.get_files_in_working_directory(files_types)
	local work_dir = vim.fn.getcwd()

	-- Build the glob pattern
	local pattern_suffix = build_glob_pattern(files_types)
	local pattern = work_dir .. "/**/" .. pattern_suffix

	return vim.tbl_map(function(f)
		return Path:new(f):absolute()
	end, vim.fn.glob(pattern, true, true))
end

--- Get metadata and cache it
---@param file string: File path.
---@return table|nil: Metadata table or nil if error occurs.
---@return string|nil: Error message if any.
function M.get_cached_metadata(file)
	-- Check cache first
	local metadata = state.get_state("files_metadata", file)

	if metadata then
		return metadata
	end

	-- Fetch and parse metadata
	metadata = duckdb.fetch_parse_data(file, "metadata")
	if not metadata then
		return nil
	end

	-- Set Cache metadata
	state.set_state("files_metadata", file, metadata)
	return metadata
end

return M
