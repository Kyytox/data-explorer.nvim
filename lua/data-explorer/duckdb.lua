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
	-- csv = [[SELECT Columns FROM sniff_csv('%s');]],
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
	-- local cmd = string.format('%s -csv -c "%s"', duckdb_cmd, query)
	-- vim.notify("Running command: " .. cmd, vim.log.levels.DEBUG)

	-- Execute the command and capture output
	-- local handle = io.popen(cmd)
	-- vim.notify("handle: " .. vim.inspect(handle), vim.log.levels.INFO)
	-- if not handle then
	-- return nil, "Error: Could not run DuckDB command. Check if DuckDB is installed and in your PATH."
	-- end

	-- Read all output
	-- local out = handle:read("*a")
	-- local success, exit_type, exit_code = handle:close()

	-- vim.notify("status: " .. tostring(success), vim.log.levels.INFO)
	-- vim.notify("exit_type: " .. vim.inspect(exit_type), vim.log.levels.INFO)
	-- vim.notify("exit_code: " .. vim.inspect(exit_code), vim.log.levels.INFO)
	-- vim.notify("output: " .. tostring(out), vim.log.levels.INFO)

	local cmd = { duckdb_cmd, "-csv", "-c", query }
	local result = vim.system(cmd, { text = true }):wait()
	local out = result.stdout
	local success = result.code == 0
	local err = result.stderr

	vim.notify("out: " .. tostring(out), vim.log.levels.DEBUG)
	vim.notify("success: " .. tostring(success), vim.log.levels.DEBUG)
	vim.notify("err: " .. tostring(err), vim.log.levels.DEBUG)

	-- Check for command failure status
	if not success or success ~= true then
		return nil, err
	end

	-- Check for empty output
	if out == "" then
		return nil, "Error: DuckDB returned empty output."
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
	local text = input:match('"(.+)"')
	if not text then
		vim.notify("No valid Columns string found.", vim.log.levels.ERROR)
		return nil, nil
	end

	-- Transform to valid JSON
	text = text:gsub("'", '"')
	vim.notify("Transformed Columns string to JSON: " .. text, vim.log.levels.DEBUG)

	-- Quote the keys
	text = text:gsub("(%w+)%s*:", '"%1":')

	-- Ensure that unquoted values are quoted (for 'name' and 'type' fields)
	text = text:gsub(":(%s*)([%w_]+)", ': "%2"')

	-- Decode the JSON string
	local ok, decoded = pcall(vim.fn.json_decode, text)
	if not ok then
		vim.notify("Failed to decode Columns string: " .. decoded, vim.log.levels.ERROR)
		return nil, nil
	end

	-- Transform into structured table
	local parsed_headers = { "Column", "type" }
	local parsed_data = {}

	for _, col in ipairs(decoded) do
		table.insert(parsed_data, {
			Column = col.name,
			type = col.type,
		})
	end

	return parsed_headers, parsed_data
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
		vim.notify("Error fetching data: " .. (err or "unknown"), vim.log.levels.ERROR)
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
				return nil, "Failed to parse metadata for CSV, TSV: "
			end
		elseif ext == ".parquet" then
			-- For Parquet metadata, use standard CSV parsing
			data_headers, data_content = parse_csv(csv_text)
			if not data_headers then
				vim.notify("Failed to parse Parquet metadata: " .. data_content, vim.log.levels.WARN)
				return nil, "Failed to parse Parquet metadata: "
			end
		end
	else
		data_headers, data_content = parse_csv(csv_text)
	end

	return { headers = data_headers, data = data_content }, nil
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

	-- Execute SQL query
	local data, err = M.fetch_parse_data(file, "query", sql_query)

	if not data then
		return err
	end

	-- Update SQL data buffer with new data
	local formatted_lines = display.prepare_data(data.headers, data.data)
	vim.api.nvim_buf_set_lines(state.get_state("buffers", "buf_data"), 0, -1, false, formatted_lines)

	return nil
end

return M
