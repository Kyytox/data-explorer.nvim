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
	     stats_min AS Min,
	     stats_max AS Max,
	     stats_null_count AS Nulls,
	     num_values AS Count
	     FROM parquet_metadata('%s');
	   ]],
	csv = [[
	       CREATE TEMP TABLE tmp AS
	       SELECT * FROM read_csv_auto('%s', auto_detect=true, sample_size=-1, ALL_VARCHAR=FALSE);
         SELECT column_name AS Column,
                column_type AS Type,
                null_percentage AS Nulls,
                SUBSTRING(min, 1, 40) AS Min,
                SUBSTRING(max, 1, 40) AS Max,
                approx_unique AS UniqueValues, 
                avg AS Average,
                std AS Std,
                q25
                q50,
                q75,
                count AS Count
          FROM (SUMMARIZE tmp);
      ]],
	tsv = [[
        CREATE TEMP TABLE tmp AS
        SELECT * FROM read_csv_auto('%s', auto_detect=true, sep='\t', sample_size=-1, ALL_VARCHAR=FALSE);
        SELECT column_name AS Column,
                column_type AS Type,
                null_percentage AS Nulls,
                SUBSTRING(min, 1, 40) AS Min,
                SUBSTRING(max, 1, 40) AS Max,
                approx_unique AS Unique, 
                avg AS Average,
                std AS Std,
                q25
                q50,
                q75,
                count AS Count
          FROM (SUMMARIZE tmp);
      ]],
	-- json = [[
	--        CREATE TEMP TABLE tmp AS SELECT * FROM read_json_auto('%s', auto_detect=true);
	--        COPY(
	--        WITH total AS (SELECT COUNT(*) AS total_rows FROM tmp)
	--        SELECT
	--          name AS Column,
	--          replace(type, ',', ';') AS Type,
	--          dflt_value AS DefaultValue,
	--          pk AS PrimaryKey,
	--          (SELECT total_rows FROM total) AS Count
	--        FROM pragma_table_info('tmp')
	--        ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
	--    ]],
}

local DATA_QUERIES = {
	parquet = [[
      COPY(
        SELECT * FROM read_parquet('%s') LIMIT %d
      ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
  ]],
	csv = [[
      COPY(
        SELECT * FROM read_csv_auto('%s') LIMIT %d
      ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
  ]],
	tsv = [[
      COPY(
        SELECT * FROM read_csv_auto('%s', sep='\t') LIMIT %d
      ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
  ]],
	-- json = [[
	--      COPY(
	--        SELECT * FROM read_json('%s') LIMIT %d
	--      ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
	--  ]],
}

--- Runs a DuckDB query and returns the raw CSV output.
--- This function is the only one that interacts with the shell.
---@param query string: The formatted SQL query.
---@return string|nil, string|nil: Raw CSV output or error message.
local function run_query(query, mode)
	local duckdb_cmd = state.get_variable("duckdb_cmd")
	local out
	local success
	local result

	if mode == "main_data" then
		-- using io.popen
		log.info("Running standard query...")
		local cmd = string.format('%s -csv -c "%s"', duckdb_cmd, query:gsub('"', '\\"'))
		result = io.popen(cmd)
		out = result:read("*a")
		success = result:close() ~= nil
	else
		-- Use vim.system to run the command because we need to capture stdout AND stderr
		local cmd = { duckdb_cmd, "-c", query }
		result = vim.system(cmd, { text = true }):wait()
		out = result.stdout
		success = result.code == 0
	end

	-- Check for command failure status
	if not success or success ~= true then
		return nil, result.stderr
	end

	-- Check for empty output
	if out == "" then
		return nil, "The request returned no data."
	end

	-- log.info(out)
	return out, nil
end

--- Validate the user-provided SQL query.
--- Will check for the presence of the required 'FROM f' syntax.
--- @param query string The raw SQL query string provided by the user.
--- @return boolean success True if the query passes all validation checks.
--- @return string message A status or error message explaining the result.
local function validate_sql_query(query)
	if not string.find(query, "from%s+f") then
		return false, "Query must use the required syntax 'FROM f' to reference the file."
	end
	return true, "Query is valid!"
end

--- Get the raw CSV metadata for a parquet file.
---@param file string: Path to the parquet file.
---@param ext string: File extension (e.g., ".parquet", ".csv").
---@return string|nil, string|nil: Raw CSV metadata or error message.
local function query_metadata(file, ext, mode)
	local query = METADATA_QUERIES[ext:sub(2)]
	query = string.format(query, file)
	return run_query(query, mode)
end

--- Get the raw CSV data (limited rows) for a parquet file.
---@param file string: Path to the parquet file.
---@param ext string: File extension (e.g., ".parquet", ".csv").
---@return string|nil, string|nil: Raw CSV data or error message.
local function query_data(file, ext, mode)
	local limit = config.get().limit
	local query = DATA_QUERIES[ext:sub(2)]
	query = string.format(query, file, limit)
	return run_query(query, mode)
end

-- Get data based on a custom SQL query
---@param file string: Path to the parquet file.
---@param query string: Custom SQL query provided by the user.
---@return string|nil, string|nil: Raw CSV data or error message.
local function query_sql(file, query, mode)
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

	return run_query(query, mode)
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

--- Fetch and parse data for a parquet file.
---@param file string|nil: File path.
---@param mode string: "main_data", "metadata", or "usr_query".
---@param query string|nil: Optional SQL query for data fetching.
---@return table|nil, string|nil: Metadata or error message.
function M.fetch_parse_data(file, mode, query)
	local start = os.clock()
	local csv_text = nil
	local err = nil

	if not file or file == "" then
		log.display_notify(4, "File path is empty!")
		return nil, "File path is empty"
	end

	-- Get file size in MB
	local size = get_file_size_mb(file)

	-- exrtact file extensions
	local ext = file:match("^.+(%..+)$")

	local result = nil

	-- Fetch Data
	if mode == "main_data" then
		csv_text, err = query_data(file, ext, mode)
		result, err = parser.parse_csv(csv_text, "|")
	elseif mode == "metadata" then
		csv_text, err = query_metadata(file, ext, mode)
		result, err = parser.parse_raw_text(csv_text)
	elseif mode == "usr_query" and query then
		csv_text, err = query_sql(file, query, mode)
		result, err = parser.parse_csv(csv_text, ",")
	end

	-- Parse Data
	if not result then
		return nil, err
	end

	local finish = os.clock()
	local elapsed = finish - start
	log.info(string.format("SQL query executed for %s in %.4f seconds.", file, elapsed))
	return { headers = result.headers, data = result.data, count_lines = result.count_lines, file_size = size }, nil
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
		log.display_notify(3, "SQL query is empty!")
		return "SQL query is empty!"
	end

	-- Execute SQL query
	local data, err = M.fetch_parse_data(file, "usr_query", sql_query)
	if not data then
		return err
	end

	-- Update SQL data buffer with new data
	local formatted_lines = display.prepare_data(data.headers, data.data)

	-- Update buffer data
	vim.api.nvim_buf_set_lines(state.get_state("buffers", "buf_data"), 0, -1, false, formatted_lines)

	return nil
end

return M
