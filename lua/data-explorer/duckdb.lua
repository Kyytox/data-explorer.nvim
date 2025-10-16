local config = require("data-explorer.config")
local state = require("data-explorer.state")
local display = require("data-explorer.ui.display")

local M = {}

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
---@param query string: The formatted SQL query.
---@return string|nil, string|nil: Raw CSV output or error message.
local function run_query(query)
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

--- Validates a given SQL query string against custom plugin rules.
--- @param query string The raw SQL query string provided by the user.
--- @return boolean success True if the query passes all validation checks.
--- @return string message A status or error message explaining the result.
local function validate_sql_query(query)
	vim.notify("Validating SQL Query..." .. query, vim.log.levels.INFO)

	-- Check for the existence of SELECT (case-insensitive)
	if not string.find(query, "select") then
		return false, "Query must contain the 'SELECT' keyword."
	end

	-- Check for the specific 'FROM f' syntax (case-insensitive)
	if not string.find(query, "from%s+f") then
		return false, "Query must use the required syntax 'FROM f' (case-insensitive)."
	end

	-- Check for the trailing semicolon (;)
	local trimmed_query = query:match("^%s*(.-)%s*$")

	if not trimmed_query:match(";$") then
		return false, "Query must end with a semicolon (;) after trimming any whitespace."
	end

	-- If all checks pass
	return true, "Query is valid!"
end

-- Example Usage (for testing purposes)
local function valid_test()
	local test_queries = {
		-- Valid
		"SELECT name, id FROM f WHERE id > 10;",
		"select count(*) from f;",
		"   SELECT * FROM F   ;  ", -- Test case and whitespace

		-- Invalid: Missing semicolon
		"SELECT * FROM f",
		-- Invalid: Wrong FROM syntax
		"SELECT * FROM users;",
		-- Invalid: Missing SELECT
		"COUNT(*) FROM f;",
		-- Invalid: Missing semicolon AND wrong FROM syntax
		"SELECT * FROM something",
	}

	print("\n--- Validating Test Queries ---")
	for _, q in ipairs(test_queries) do
		local success, message = validate_sql_query(q)
		print(string.format("[PASS: %s] Query: '%s'\n\t-> Message: %s", tostring(success), q, message))
	end
end

--- Get the raw CSV metadata for a parquet file.
---@param file string: Path to the parquet file.
---@return string|nil, string|nil: Raw CSV metadata or error message.
local function query_metadata(file)
	local query = string.format(QUERY_METADATA, file)
	return run_query(query)
end

--- Get the raw CSV data (limited rows) for a parquet file.
---@param file string: Path to the parquet file.
---@return string|nil, string|nil: Raw CSV data or error message.
local function query_data(file)
	local limit = config.get().limit
	local query = string.format(QUERY_DATA, file, limit)
	return run_query(query)
end

-- Get data based on a custom SQL query
---@param file string: Path to the parquet file.
---@param query string: Custom SQL query provided by the user.
---@return string|nil, string|nil: Raw CSV data or error message.
local function query_sql(file, query)
	-- Convert query to lower case
	query = string.lower(query)

	local is_valid, msg = validate_sql_query(query)

	if not is_valid then
		vim.notify("Invalid SQL Query: " .. msg, vim.log.levels.WARN)
		return nil, msg
	end

	-- transform to 'from ('path/to/file')'
	local path_file = file:gsub("'", "\\'")
	query = query:gsub("from%s+f", "FROM '" .. path_file .. "'")
	-- query = string.format(query, file)

	vim.notify("Transformed Query: " .. query, vim.log.levels.INFO)

	return run_query(query)
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

--- Fetch and parse data for a parquet file.
---@param file string|nil: File path.
---@param type string: "data", "metadata", query"
---@param query string|nil: Optional SQL query for data fetching.
---@return table|nil, string|nil: Metadata or error message.
function M.fetch_parse_data(file, type, query)
	local csv_text = nil
	local err = nil

	if not file or file == "" then
		return nil, "File path is empty"
	end

	-- Fetch Data
	if type == "data" then
		csv_text, err = query_data(file)
	elseif type == "metadata" then
		csv_text, err = query_metadata(file)
	elseif type == "query" and query then
		csv_text, err = query_sql(file, query)
	end

	if not csv_text then
		vim.notify("DuckDB error: " .. (err or "unknown"), vim.log.levels.ERROR)
		return nil, err
	end

	-- Parse CSV data
	local data_headers, data_content = M.parse_csv(csv_text)
	if not data_headers then
		vim.notify("Failed to parse CSV: " .. data_content, vim.log.levels.WARN)
		return nil, "Failed to parse CSV: " .. (data_content or "unknown")
	end

	return { headers = data_headers, data = data_content }, nil
end

--- Execute the SQL query
---@param opts table: Options table.
---@param buf number: Buffer number containing the SQL query.
function M.execute_sql_query(opts, buf)
	local file = state.get_state("current_file")

	-- Get SQL query from SQL buffer
	local sql_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local sql_query = table.concat(sql_lines, " ")

	-- Simple validation
	if sql_query:match("^%s*$") then
		vim.notify("SQL query is empty!", vim.log.levels.WARN)
		return "SQL query is empty!"
	end

	-- Execute SQL query
	local data, err = M.fetch_parse_data(file, "query", sql_query)

	if not data then
		vim.notify("Error executing query: " .. (err or "unknown"), vim.log.levels.ERROR)
		return err
	end

	-- Update SQL data buffer with new data
	local formatted_lines = display.prepare_data(data.headers, data.data)
	vim.api.nvim_buf_set_lines(state.get_state("buffers", "buf_data"), 0, -1, false, formatted_lines)

	return nil
end

return M
