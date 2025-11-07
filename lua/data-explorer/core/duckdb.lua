local log = require("data-explorer.gestion.log")
local state = require("data-explorer.gestion.state")
local display = require("data-explorer.ui.display")
local parser = require("data-explorer.core.parser")
local config_windows = require("data-explorer.ui.config_windows")

local M = {}
local TABLE_NAME = "f"

local QUERY_TEMPLATE = {
	parquet = {
		metadata = [[
      SELECT
      path_in_schema AS Column,
      type AS Type,
      stats_min AS Min,
      stats_max AS Max,
      stats_null_count AS Nulls,
      num_values AS Count
      FROM parquet_metadata('%s');
    ]],
		data = [[SELECT * FROM read_parquet('%s') LIMIT %d OFFSET %d;]],
		data_store_duckdb = [[
      CREATE OR REPLACE TABLE %s AS SELECT * FROM read_parquet('%s');
      SELECT * FROM %s LIMIT %d OFFSET %d;
    ]],
	},
	csv = {
		metadata = [[
      WITH tmp AS (SELECT * FROM read_csv_auto('%s', auto_detect=true, sample_size=-1))
      SELECT
          column_name AS Column,
          column_type AS Type,
          approx_unique AS Unique,
          null_percentage AS Nulls,
          SUBSTRING(min, 1, 40) AS Min,
          SUBSTRING(max, 1, 40) AS Max,
          avg AS Average,
          std AS Std,
          q25,
          q50,
          q75,
          count AS Count
      FROM (SUMMARIZE (SELECT * FROM tmp));
    ]],
		data = [[SELECT * FROM read_csv_auto('%s', sample_size=-1) LIMIT %d OFFSET %d;]],
		data_store_duckdb = [[
      CREATE OR REPLACE TABLE %s AS SELECT * FROM read_csv_auto('%s', sample_size=-1);
      SELECT * FROM %s LIMIT %d OFFSET %d;
    ]],
	},
	tsv = {
		metadata = [[
      WITH tmp AS (SELECT * FROM read_csv_auto('%s', sep='\t', auto_detect=true, sample_size=-1))
      SELECT
          column_name AS Column,
          column_type AS Type,
          approx_unique AS Unique,
          null_percentage AS Nulls,
          SUBSTRING(min, 1, 40) AS Min,
          SUBSTRING(max, 1, 40) AS Max,
          avg AS Average,
          std AS Std,
          q25,
          q50,
          q75,
          count AS Count
      FROM (SUMMARIZE (SELECT * FROM tmp));
    ]],
		data = [[SELECT * FROM read_csv_auto('%s', sep='\t', sample_size=-1) LIMIT %d OFFSET %d;]],
		data_store_duckdb = [[
      CREATE OR REPLACE TABLE %s AS SELECT * FROM read_csv_auto('%s', sep='\t', sample_size=-1);
      SELECT * FROM %s LIMIT %d OFFSET %d;
    ]],
	},
}

--- Generates the DuckDB command to execute a query.
--- @param query string The SQL query to execute.
--- @param top_store_duckdb boolean Whether to use the DuckDB storage file.
--- @param limit number The maximum number of rows to return.
--- @return table The command and its arguments as a table.
local function generate_duckdb_command(query, top_store_duckdb, limit)
	local duckdb_cmd = state.get_variable("duckdb_cmd")
	local args = {
		duckdb_cmd,
		"-cmd",
		".maxrows " .. tostring(limit),
		"-cmd",
		".nullvalue ''",
		"-c",
		query,
	}

	if top_store_duckdb then
		local path_db = vim.fn.stdpath("data") .. state.get_variable("data_dir") .. state.get_variable("duckdb_file")
		table.insert(args, 2, path_db)
	end

	return args
end

--- Runs a DuckDB query and returns the output.
--- @param query string The SQL query to execute.
--- @param top_storage_duckdb boolean Whether to use the DuckDB storage file.
--- @param limit number The maximum number of rows to return.
--- @return string|nil The output of the query, or nil if an error occurred.
--- @return string|nil An error message if an error occurred, or nil on success.
local function run_query(query, top_storage_duckdb, limit)
	local cmd = generate_duckdb_command(query, top_storage_duckdb, limit)

	local result
	result = vim.system(cmd, { text = true }):wait()

	if result.code ~= 0 then
		return nil, result.stderr
	end

	if result.stdout == "" then
		return nil, "The request returned no data."
	end

	return result.stdout, nil
end

--- Prepares a SQL query
--- @param file string The path to the data file.
--- @param ext string The file extension (e.g., "csv", "parquet").
--- @param mode string The mode of the query ("metadata" or "main_data").
--- @param top_store_duckdb boolean Whether to use the DuckDB storage file.
--- @param limit number|nil The maximum number of rows to return.
--- @param offset number|nil The offset for pagination.
--- @return string|nil The prepared SQL query, or nil if an error occurred.
--- @return string|nil An error message if an error occurred, or nil on success.
local function prepare_query(file, ext, mode, top_store_duckdb, limit, offset)
	local temp = QUERY_TEMPLATE[ext]
	local template = (mode == "metadata") and temp.metadata or top_store_duckdb and temp.data_store_duckdb or temp.data

	local query
	if mode == "metadata" then
		query = string.format(template, file)
	else
		if top_store_duckdb then
			query = string.format(template, TABLE_NAME, file, TABLE_NAME, limit, offset)
		else
			query = string.format(template, file, limit, offset)
		end
	end

	return query, nil
end

--- Fetches metadata for the given file.
--- @param file string The path to the data file.
--- @param ext string The file extension (e.g., "csv", "parquet").
--- @return table|nil The metadata including headers, data, and count of lines, or nil if an error occurred.
--- @return string|nil An error message if an error occurred, or nil on success.
function M.fetch_metadata(file, ext)
	local query, err = prepare_query(file, ext, "metadata", false, nil, nil)
	if err then
		return nil, err
	end

	-- Run the query
	local csv_text, err = run_query(query, false, 1000)
	if err then
		return nil, err
	end

	-- Parse Data
	local result, err = parser.parse_raw_text(csv_text, "metadata")

	if not result then
		return nil, err
	end

	return { headers = result.headers, data = result.data, count_lines = result.count_lines }, nil
end

--- Fetches main data for the given file.
--- @param file string The path to the data file.
--- @param ext string The file extension (e.g., "csv", "parquet").
--- @param top_store_duckdb boolean Whether to use the DuckDB storage file.
--- @param limit number The maximum number of rows to return.
--- @return table|nil The main data as a table of rows, or nil if an error occurred.
--- @return string|nil An error message if an error occurred, or nil on success.
function M.fetch_main_data(file, ext, top_store_duckdb, limit)
	local query, err = prepare_query(file, ext, "main_data", top_store_duckdb, limit, 0)
	if err then
		return nil, err
	end

	-- Run the query
	local csv_text, err = run_query(query, top_store_duckdb, limit)
	if err then
		return nil, err
	end

	local result, err = parser.parse_raw_text(csv_text, nil)

	if not result then
		return nil, err
	end

	return result.data, nil
end

--- Validates a SQL query provided by the user.
--- @param query string The SQL query to validate.
--- @return boolean True if the query is valid, false otherwise.
--- @return string A message indicating the validation result.
local function validate_sql_query(query)
	if query:match("^%s*$") then
		log.display_notify(3, "SQL query is empty!")
		return false, "SQL query is empty!"
	end

	if not string.find(query, "from%s+f") then
		return false, "Query must use the required syntax 'FROM f' to reference the file."
	end
	return true, "Query is valid!"
end

--- Prepares a user-provided SQL query for execution.
--- @param file string The path to the data file.
--- @param query string The user-provided SQL query.
--- @param top_store_duckdb boolean Whether to use the DuckDB storage file.
--- @param limit number The maximum number of rows to return.
--- @param offset number The offset for pagination.
--- @return string|nil The prepared SQL query, or nil if an error occurred.
--- @return string|nil An error message if an error occurred, or nil on success.
local function prepare_user_query(file, query, top_store_duckdb, limit, offset)
	query = string.lower(query)

	-- Validate SQL query
	local is_valid, err = validate_sql_query(query)
	if not is_valid then
		return nil, err
	end

	-- Remove ; at the end
	query = query:gsub(";%s*$", "")

	if not top_store_duckdb then
		local path_file = vim.fn.fnameescape(file)
		query = query:gsub("from%s+f", "FROM '" .. path_file .. "'")
	end
	query = string.format("SELECT * FROM (%s) LIMIT %d OFFSET %d", query, limit, offset)

	return query, nil
end

--- Executes a user-provided SQL query and updates the buffer with the results.
--- @param opts table Options for executing the query, including limit and storage settings.
--- @param buf number The buffer number containing the SQL query.
--- @return string|nil An error message if an error occurred, or nil on success.
function M.execute_sql_query(opts, buf)
	local file = state.get_state("current_file")
	local limit = opts.limit
	local top_store_duckdb = opts.use_storage_duckdb

	-- Get SQL query from SQL buffer
	local sql_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local sql_query = table.concat(sql_lines, " ")

	-- Execute SQL query
	local new_query, err = prepare_user_query(file, sql_query, top_store_duckdb, limit, 0)
	if not new_query then
		return err
	end

	-- Run the query
	local out_data, err = run_query(new_query, top_store_duckdb, limit)
	if not out_data then
		return err
	end

	--Parse Data
	local result, err = parser.parse_raw_text(out_data, nil)
	if not result then
		return err
	end

	-- Store last user query in state
	state.set_state("last_user_query", nil, sql_query)
	state.set_state("num_page", nil, 1)

	-- Update buffer data
	local buf_data = state.get_state("buffers", "buf_data")
	local win_data = state.get_state("windows", "win_data")
	M.update_buffer(opts.hl.buffer.hl_enable, win_data, buf_data, result.data, 1)

	-- Calculate window layout
	local tbl_dims = config_windows.calculate_window_layout(
		opts,
		vim.o.columns,
		vim.o.lines,
		tonumber(vim.inspect(state.get_state("tbl_dimensions", opts.layout).meta_height)),
		#result.data
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

--- Retrieves paginated data
--- @param opts table Options for pagination, including limit and storage settings.
--- @param digit number The page increment (positive for next page, negative for previous page).
--- @return string|nil An error message if an error occurred, or nil on success.
function M.get_data_pagination(opts, digit)
	local top_store_duckdb = opts.use_storage_duckdb
	local limit = opts.limit
	local last_user_query = state.get_state("last_user_query")
	local file = state.get_state("current_file")
	local ext = state.get_state("files_metadata", file).file_ext
	local max_num_page = state.get_state("max_num_page")
	local page = state.get_state("num_page")
	local new_page = page + digit

	if new_page < 1 then
		log.display_notify(3, "Already at the first page.")
		return
	elseif new_page > max_num_page then
		log.display_notify(3, "Already at the last page.")
		return
	end

	local offset = (new_page - 1) * limit

	local query
	local err
	log.debug("last_user_query: " .. tostring(last_user_query))
	if type(last_user_query) == "string" and last_user_query ~= "" then
		query, err = prepare_user_query(file, last_user_query, top_store_duckdb, limit, offset)
	else
		if top_store_duckdb then
			query = "SELECT * FROM f"
			query = string.format("SELECT * FROM (%s) LIMIT %d OFFSET %d", query, limit, offset)
		else
			query = QUERY_TEMPLATE[ext].data
			query = string.format(query, file, limit, offset)
		end
	end

	-- Generate the duckdb command
	local csv_text, err = run_query(query, top_store_duckdb, limit)
	if err then
		return nil, err
	end
	local result, err = parser.parse_raw_text(csv_text, nil)

	if not result then
		return nil, err
	end

	state.set_state("num_page", nil, new_page)

	-- remove and update buffer data
	local buf_data = state.get_state("buffers", "buf_data")
	local win_data = state.get_state("windows", "win_data")
	M.update_buffer(opts.hl.buffer.hl_enable, win_data, buf_data, result.data, new_page)
end

function M.update_buffer(hl_enable, win_data, buf_data, data, page)
	-- Update buffer data
	vim.api.nvim_buf_set_lines(buf_data, 0, -1, false, data)

	-- Update title with page number
	if page then
		local title = string.format(" Data View - Page %d ", page)
		config_windows.update_window_title(win_data, title)
	end

	if hl_enable then
		display.update_highlights(buf_data, data)
	end
end

return M
