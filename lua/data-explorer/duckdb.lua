local M = {}
local config = require("data-explorer.config")

-- DuckDB SQL queries
local QUERY_METADATA = [[
    SELECT
    path_in_schema AS Column,
    type AS Type,
    num_values AS Count,
    stats_min AS Min,
    stats_max AS Max,
    stats_null_count AS Null
    FROM parquet_metadata('%s');]]

local QUERY_DATA = [[SELECT * FROM read_parquet('%s') LIMIT %d;]]

--- Runs a DuckDB query and returns the raw CSV output.
--- This function is the only one that interacts with the shell.
---@param file string: Path to the parquet file.
---@param query string: The formatted SQL query.
---@return string|nil, string|nil: Raw CSV output or error message.
local function run_query(file, query)
	local duckdb_cmd = config.get().duckdb_cmd -- Get the command path from config
	local cmd = string.format('%s -csv -c "%s"', duckdb_cmd, query)

	local handle = io.popen(cmd)

	if not handle then
		return nil, "Error: Could not run DuckDB command. Check if DuckDB is installed and in your PATH."
	end

	local out = handle:read("*a")
	local status = handle:close()

	if out == "" then
		return nil, "No output returned from DuckDB."
	end

	-- Check for command failure status (optional, but good)
	if not status or status ~= true then
		return nil, "DuckDB command failed or returned non-zero exit code."
	end

	return out, nil
end

--- Get the raw CSV metadata for a parquet file.
---@param file string: Path to the parquet file.
---@return string|nil, string|nil: Raw CSV metadata or error message.
function M.get_metadata_csv(file)
	local query = string.format(QUERY_METADATA, file)
	return run_query(file, query)
end

--- Get the raw CSV data (limited rows) for a parquet file.
---@param file string: Path to the parquet file.
---@return string|nil, string|nil: Raw CSV data or error message.
function M.get_data_csv(file)
	local limit = config.get().limit
	local query = string.format(QUERY_DATA, file, limit)
	return run_query(file, query)
end

--- Parse CSV text into a structured table.
---@param csv_text string: CSV text to parse.
---@return table|nil, table|nil: Headers and data, or error message.
function M.parse_csv(csv_text)
	local lines = vim.split(vim.trim(csv_text), "\n", { plain = true })
	if #lines < 2 then
		return nil, nil
	end

	local headers = vim.split(lines[1], ",", { plain = true })
	local data = {}

	for i = 2, #lines do
		local values = vim.split(lines[i], ",", { plain = true })
		local row = {}
		for j, key in ipairs(headers) do
			row[key] = values[j] or ""
		end
		table.insert(data, row)
	end

	return headers, data
end

return M
