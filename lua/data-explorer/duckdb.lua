local config = require("data-explorer.config")
local state = require("data-explorer.state")
local display = require("data-explorer.ui.display")

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
	csv = [[SELECT Columns FROM sniff_csv('%s');]],
	tsv = [[SELECT Columns FROM sniff_csv('%s', header=true, sep='\t');]],
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
	local cmd = string.format('%s -csv -c "%s"', duckdb_cmd, query)

	-- Execute the command and capture output
	local handle = io.popen(cmd)
	if not handle then
		return nil, "Error: Could not run DuckDB command. Check if DuckDB is installed and in your PATH."
	end

	-- Read all output
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

--- Get the raw CSV metadata for a parquet file.
---@param file string: Path to the parquet file.
---@param ext string: File extension (e.g., ".parquet", ".csv").
---@return string|nil, string|nil: Raw CSV metadata or error message.
local function query_metadata(file, ext)
	-- Get the appropriate query template based on file extension
	local query = METADATA_QUERIES[ext:sub(2)] -- Remove the leading dot
	query = string.format(query, file)
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
	local is_valid, msg = validate_sql_query(query)
	if not is_valid then
		vim.notify("Invalid SQL Query: " .. msg, vim.log.levels.WARN)
		return nil, msg
	end

	-- transform to 'from ('path/to/file')'
	local path_file = file:gsub("'", "\\'")
	query = query:gsub("from%s+f", "FROM '" .. path_file .. "'")

	return run_query(query)
end

--- Parse CSV text into a structured table.
---@param csv_text string: CSV text to parse.
---@return table|nil, table|nil: Headers and data, or error message.
local function parse_csv(csv_text)
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

--- Parse the 'Columns' string from CSV/TSV metadata into a structured table.
---@param input string: The raw 'Columns' string from DuckDB.
---@return table|nil, table|nil: Parsed headers and data, or error message.
local function parse_columns_string(input)
	-- Extract the JSON-like substring
	local s = input:match('"(.+)"')
	if not s then
		vim.notify("No valid Columns string found.", vim.log.levels.ERROR)
		return nil, nil
	end

	-- Transform to valid JSON
	s = s:gsub("'", '"')

	-- Quote the keys
	s = s:gsub("(%w+)%s*:", '"%1":')

	-- Ensure that unquoted values are quoted (for 'name' and 'type' fields)
	s = s:gsub(":(%s*)([%w_]+)", ': "%2"')

	-- Decode the JSON string
	local ok, decoded = pcall(vim.fn.json_decode, s)
	if not ok then
		vim.notify("Failed to decode Columns string: " .. decoded, vim.log.levels.ERROR)
		return nil, nil
	end

	-- Transform into structured table
	local Parsed_CSV_Headers = { "Column", "type" }
	local Parsed_CSV_Data = {}

	for _, col in ipairs(decoded) do
		table.insert(Parsed_CSV_Data, {
			Column = col.name,
			type = col.type,
		})
	end

	return Parsed_CSV_Headers, Parsed_CSV_Data
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
		vim.notify("DuckDB error: " .. (err or "unknown"), vim.log.levels.ERROR)
		return nil, err
	end

	-- Parse Data
	local data_headers, data_content = nil, nil

	if type == "metadata" then
		if ext == ".csv" or ext == ".tsv" then
			-- For CSV/TSV metadata, parse differently
			data_headers, data_content = parse_columns_string(csv_text)
			if not data_headers then
				vim.notify("Failed to parse metadata for CSV, TSV: " .. data_content, vim.log.levels.WARN)
				return nil, "Failed to parse metadata for CSV, TSV: " .. (data_content or "unknown")
			end
		elseif ext == ".parquet" then
			-- For Parquet metadata, use standard CSV parsing
			data_headers, data_content = parse_csv(csv_text)
			if not data_headers then
				vim.notify("Failed to parse Parquet metadata: " .. data_content, vim.log.levels.WARN)
				return nil, "Failed to parse Parquet metadata: " .. (data_content or "unknown")
			end
		end
	else
		data_headers, data_content = parse_csv(csv_text)
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
