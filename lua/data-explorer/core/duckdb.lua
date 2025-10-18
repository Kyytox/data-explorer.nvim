local log = require("data-explorer.gestion.log")
local config = require("data-explorer.gestion.config")
local state = require("data-explorer.gestion.state")
local display = require("data-explorer.ui.display")
local parser = require("data-explorer.core.parser")

local M = {}

-- DuckDB SQL queries
local METADATA_QUERIES = {
	parquet = [[
    SELECT
    path_in_schema AS Column,
    type AS Type,
    num_values AS Count,
    stats_min AS Min,
    stats_max AS Max,
    stats_null_count AS Null
    FROM parquet_metadata('%s');]],
	csv = [[
        WITH ligne_count AS (
            SELECT COUNT(*) AS total FROM read_csv('%s', auto_detect=true)
        )
        SELECT
            Columns,
            (SELECT total FROM ligne_count) AS nombre_lignes
        FROM
            sniff_csv('%s', auto_detect=true);
    ]],
	tsv = [[
        WITH ligne_count AS (
            SELECT COUNT(*) AS total FROM read_csv('%s', header=true, sep='\t', auto_detect=true)
        )
        SELECT
            Columns,
            (SELECT total FROM ligne_count) AS nombre_lignes
        FROM
            sniff_csv('%s', header=true, sep='\t', auto_detect=true);
    ]],
}

local DATA_QUERIES = {
	parquet = "SELECT * FROM read_parquet('%s') LIMIT %d;",
	csv = "SELECT * FROM read_csv_auto('%s') LIMIT %d;",
	tsv = "SELECT * FROM read_csv_auto('%s', sep='\t') LIMIT %d;",
}

--- Runs a DuckDB query and returns the raw CSV output.
--- This function is the only one that interacts with the shell.
---@param query string: The formatted SQL query.
---@return string|nil, string|nil: Raw CSV output or error message.
local function run_query(query)
	local duckdb_cmd = config.get().duckdb_cmd -- Get the command path from config
	local cmd = { duckdb_cmd, "-csv", "-c", query }
	local result = vim.system(cmd, { text = true }):wait()
	local out = result.stdout
	local success = result.code == 0

	-- Check for command failure status
	if not success or success ~= true then
		return nil, result.stderr
	end

	-- Check for empty output
	if out == "" then
		return nil, "The request returned no data."
	end

	return out, nil
end

--- Validate the user-provided SQL query to ensure it meets required syntax.
--- @param query string The raw SQL query string provided by the user.
--- @return boolean success True if the query passes all validation checks.
--- @return string message A status or error message explaining the result.
local function validate_sql_query(query)
	-- Check for the specific 'FROM f' syntax
	if not string.find(query, "from%s+f") then
		return false, "Query must use the required syntax 'FROM f' to reference the file."
	end

	-- If all checks pass
	return true, "Query is valid!"
end

--- Get the raw CSV metadata for a parquet file.
---@param file string: Path to the parquet file.
---@param ext string: File extension (e.g., ".parquet", ".csv").
---@return string|nil, string|nil: Raw CSV metadata or error message.
local function query_metadata(file, ext)
	-- Get the appropriate query template based on file extension
	local query = METADATA_QUERIES[ext:sub(2)] -- Remove the leading dot
	query = string.format(query, file, file)
	return run_query(query)
end

--- Get the raw CSV data (limited rows) for a parquet file.
---@param file string: Path to the parquet file.
---@param ext string: File extension (e.g., ".parquet", ".csv").
---@return string|nil, string|nil: Raw CSV data or error message.
local function query_data(file, ext)
	local limit = config.get().limit

	-- Get the appropriate query template based on file extension
	local query = DATA_QUERIES[ext:sub(2)] -- Remove the leading dot
	query = string.format(query, file, limit)
	return run_query(query)
end

-- Get data based on a custom SQL query
---@param file string: Path to the parquet file.
---@param query string: Custom SQL query provided by the user.
---@return string|nil, string|nil: Raw CSV data or error message.
local function query_sql(file, query)
	-- Convert query to lower case
	query = string.lower(query)

	-- Validate SQL query
	local is_valid, err = validate_sql_query(query)
	if not is_valid then
		return nil, err
	end

	-- transform to 'from ('path/to/file')'
	local path_file = file:gsub("'", "\\'")
	query = query:gsub("from%s+f", "FROM '" .. path_file .. "'")

	return run_query(query)
end

--- Fetch and parse data for a parquet file.
---@param file string|nil: File path.
---@param type string: "data", "metadata", query"
---@param query string|nil: Optional SQL query for data fetching.
---@return table|nil, string|nil: Metadata or error message.
function M.fetch_parse_data(file, type, query)
	local csv_text = nil
	local err = nil

	if not file or file == "" then
		vim.notify("File path is empty!", vim.log.levels.WARN)
		return nil, "File path is empty"
	end

	-- exrtact file extensions
	local ext = file:match("^.+(%..+)$")

	-- Fetch Data
	if type == "data" then
		csv_text, err = query_data(file, ext)
	elseif type == "metadata" then
		csv_text, err = query_metadata(file, ext)
	elseif type == "query" and query then
		csv_text, err = query_sql(file, query)
	end

	if not csv_text then
		vim.notify("Error: " .. (err or "unknown"), vim.log.levels.ERROR)
		return nil, err
	end

	-- Parse Data
	local result = nil
	if type == "metadata" then
		if ext == ".csv" or ext == ".tsv" then
			result = parser.parse_columns_string(csv_text)
			-- log.info(vim.inspect(result))
		elseif ext == ".parquet" then
			result = parser.parse_csv(csv_text)
		end
	else
		result = parser.parse_csv(csv_text)
	end

	if not result then
		vim.notify("No result from parsing.", vim.log.levels.ERROR)
		return nil, "No result from parsing."
	end

	return { headers = result.headers, data = result.data, count_lines = result.count_lines }, nil
end

--- Execute the SQL query
---@param buf number: Buffer number containing the SQL query.
function M.execute_sql_query(buf)
	local file = state.get_state("current_file")

	-- Get SQL query from SQL buffer
	local sql_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local sql_query = table.concat(sql_lines, " ")

	-- Simple validation
	if sql_query:match("^%s*$") then
		vim.notify("SQL query is empty!", vim.log.levels.WARN)
		return "SQL query is empty!"
	end
	local start = os.clock()

	-- Execute SQL query
	local data, err = M.fetch_parse_data(file, "query", sql_query)
	if not data then
		return err
	end

	-- Update SQL data buffer with new data
	local formatted_lines = display.prepare_data(data.headers, data.data)

	-- Updatebuffer data
	vim.api.nvim_buf_set_lines(state.get_state("buffers", "buf_data"), 0, -1, false, formatted_lines)

	local finish = os.clock()
	local elapsed = finish - start
	log.info(string.format("SQL query executed in %.4f seconds.", elapsed))

	return nil
end

return M
