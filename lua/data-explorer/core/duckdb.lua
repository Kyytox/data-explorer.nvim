local log = require("data-explorer.gestion.log")
local config = require("data-explorer.gestion.config")
local state = require("data-explorer.gestion.state")
local display = require("data-explorer.ui.display")
local parser = require("data-explorer.core.parser")
local config_windows = require("data-explorer.ui.config_windows")

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
	       SELECT * FROM read_csv_auto('%s', auto_detect=true, sample_size=-1);
         SELECT column_name AS Column,
                column_type AS Type,
                approx_unique AS Unique,
                null_percentage AS Nulls,
                SUBSTRING(min, 1, 40) AS Min,
                SUBSTRING(max, 1, 40) AS Max,
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
        SELECT * FROM read_csv_auto('%s', auto_detect=true, sep='\t', sample_size=-1);
         SELECT column_name AS Column,
                column_type AS Type,
                approx_unique AS Unique,
                null_percentage AS Nulls,
                SUBSTRING(min, 1, 40) AS Min,
                SUBSTRING(max, 1, 40) AS Max,
                avg AS Average,
                std AS Std,
                q25
                q50,
                q75,
                count AS Count
          FROM (SUMMARIZE tmp);
      ]],
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
}

--- Runs a DuckDB query and returns the raw CSV output.
--- This function is the only one that interacts with the shell.
---@param cmd string|table: The command string or table to execute.
---@param mode string: "main_data", "metadata", or "usr_query".
---@return string|nil, string|nil: Raw CSV output or error message.
local function run_query(cmd, mode)
	local out
	local success
	local result

	if mode == "main_data" then
		-- using io.popen
		result = io.popen(cmd)
		out = result:read("*a")
		success = result:close() ~= nil
	else
		-- Use vim.system to run the command because we need to capture stdout AND stderr
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

--- Generate command to run DuckDB query
---@param query string: The SQL query to execute.
---@param mode string: "main_data", "metadata", or "usr_query".
---@return string|table: The command string or table to execute.
local function generate_duckdb_command(query, mode)
	local duckdb_cmd = state.get_variable("duckdb_cmd")
	local cmd = nil

	if mode == "main_data" then
		cmd = string.format('%s -csv -c "%s"', duckdb_cmd, query:gsub('"', '\\"'))
	elseif mode == "usr_query" then
		cmd = { duckdb_cmd, "-csv", "-c", query }
	else
		cmd = { duckdb_cmd, "-c", query }
	end

	return cmd
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

--- Prepare command for fetching metadata.
---@param file string: Path to the parquet file.
---@param ext string: File extension (e.g., ".parquet", ".csv").
---@return string|nil, string|nil: Raw CSV metadata or error message.
local function prepare_cmd_metadata(file, ext, mode)
	-- Format the query
	local query = METADATA_QUERIES[ext:sub(2)]
	query = string.format(query, file)

	-- Generate the duckdb command
	local cmd = generate_duckdb_command(query, mode)
	return run_query(cmd, mode)
end

--- Prepare command for fetching main data.
---@param file string: Path to the parquet file.
---@param ext string: File extension (e.g., ".parquet", ".csv").
---@param limit number: Number of rows to fetch.
---@return string|nil, string|nil: Raw CSV data or error message.
local function prepare_cmd_main_data(file, ext, mode, limit)
	-- Format the query
	local query = DATA_QUERIES[ext:sub(2)]
	query = string.format(query, file, limit)

	-- Generate the duckdb command
	local cmd = generate_duckdb_command(query, mode)
	return run_query(cmd, mode)
end

--- Prepare command for executing user-provided SQL query.
---@param file string: Path to the parquet file.
---@param query string: Custom SQL query provided by the user.
---@return string|nil, string|nil: Raw CSV data or error message.
local function prepare_cmd_user_query(file, query, mode)
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

	-- Generate the duckdb command
	local cmd = generate_duckdb_command(query, mode)
	return run_query(cmd, mode)
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
function M.fetch_parse_data(file, mode, query, limit)
	-- local start = os.clock()
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
		csv_text, err = prepare_cmd_main_data(file, ext, mode, limit)
		result, err = parser.parse_csv(csv_text, "|")
	elseif mode == "metadata" then
		csv_text, err = prepare_cmd_metadata(file, ext, mode)
		result, err = parser.parse_raw_text(csv_text)
	elseif mode == "usr_query" and query then
		csv_text, err = prepare_cmd_user_query(file, query, mode)
		result, err = parser.parse_csv(csv_text, ",")
	end

	-- Parse Data
	if not result then
		return nil, err
	end

	-- local finish = os.clock()
	-- local elapsed = finish - start
	-- log.info(string.format("SQL query executed for %s in %.4f seconds.", file, elapsed))
	return { headers = result.headers, data = result.data, count_lines = result.count_lines, file_size = size }, nil
end

--- Execute the SQL query write by the user
---@param opts table: Options table.
---@param buf number: Buffer number containing the SQL query.
function M.execute_sql_query(opts, buf)
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
	local buf_data = state.get_state("buffers", "buf_data")
	vim.api.nvim_buf_set_lines(buf_data, 0, -1, false, formatted_lines)

	local hl_enable = opts.hl.buffer.hl_enable
	if hl_enable then
		display.update_highlights(buf_data, formatted_lines)
	end

	-- Update dimensions of windows
	-- Calculate window layout
	local tbl_dims = config_windows.calculate_window_layout(
		opts,
		vim.o.columns,
		vim.o.lines,
		tonumber(vim.inspect(state.get_state("tbl_dimensions", opts.layout).meta_height)),
		#data.data
	)

	-- get windows layout info according to the layout
	tbl_dims = tbl_dims[opts.layout]

	-- Update metadata window
	config_windows.update_window_dimensions(
		state.get_state("windows", "win_meta"),
		tbl_dims.meta_width,
		tbl_dims.meta_height,
		tbl_dims.row_start,
		tbl_dims.col_start
	)

	-- Update data window
	config_windows.update_window_dimensions(
		state.get_state("windows", "win_data"),
		tbl_dims.main_width,
		tbl_dims.data_height,
		tbl_dims.data_row_start,
		tbl_dims.data_col_start
	)

	return nil
end

return M
