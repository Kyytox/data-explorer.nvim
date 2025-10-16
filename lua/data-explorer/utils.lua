local Path = require("plenary.path")
local duckdb = require("data-explorer.duckdb")
local state = require("data-explorer.state")

local M = {}

--- Get all files in working directory
function M.get_files_in_working_directory()
	local work_dir = vim.fn.getcwd()
	return vim.tbl_map(function(f)
		return Path:new(f):absolute()
	end, vim.fn.glob(work_dir .. "/**/*.parquet", true, true))
end

--- Get metadata and cache it
---@param file string: File path.
function M.get_cached_metadata(file)
	local err = nil

	-- Check cache first
	local metadata = state.get_state("files_metadata", file)

	if metadata then
		return metadata
	end

	-- Fetch and parse metadata
	metadata, err = duckdb.fetch_parse_data(file, "metadata")
	if not metadata then
		return nil, err
	end

	-- Set Cache metadata
	state.set_state("files_metadata", file, metadata)

	return metadata
end

return M
