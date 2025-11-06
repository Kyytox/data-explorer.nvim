local log = require("data-explorer.gestion.log")
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
	parquet = [[SELECT * FROM read_parquet('%s') LIMIT %d OFFSET %d;]],
	csv = [[SELECT * FROM read_csv_auto('%s', sample_size=-1) LIMIT %d OFFSET %d;]],
	tsv = [[SELECT * FROM read_csv_auto('%s', sep='\t', sample_size=-1) LIMIT %d OFFSET %d;]],
}

local TABLE_NAME = "f"
local DATA_QUERIES_STORE_DUCKDB = {
	parquet = [[
      CREATE OR REPLACE TABLE %s AS SELECT * FROM read_parquet('%s');
      SELECT * FROM %s LIMIT %d OFFSET %d;
  ]],
	csv = [[
      CREATE OR REPLACE TABLE %s AS SELECT * FROM read_csv_auto('%s', sample_size=-1);
      SELECT * FROM %s LIMIT %d OFFSET %d;
  ]],
	tsv = [[
      CREATE OR REPLACE TABLE %s AS SELECT * FROM read_csv_auto('%s', sep='\t', sample_size=-1);
      SELECT * FROM %s LIMIT %d OFFSET %d;
  ]],
}

--- Runs a DuckDB query and returns the raw CSV output.
--- This function is the only one that interacts with the shell.
---@return string|nil, string|nil: Raw CSV output or error message.
local function run_query(cmd)
	local result

	-- log.debug("Running DuckDB command: " .. table.concat(cmd, " "))
	result = vim.system(cmd, { text = true }):wait()

	if result.code ~= 0 then
		log.display_notify(4, "DuckDB query execution failed: " .. (result.stderr or "Unknown error"))
		return nil, result.stderr
	end

	if result.stdout == "" then
		return nil, "The request returned no data."
	end
	return result.stdout, nil
end

local function generate_duckdb_command(query, top_store_duckdb, limit)
	local duckdb_cmd = state.get_variable("duckdb_cmd")

	if top_store_duckdb then
		local path_db = vim.fn.stdpath("data") .. state.get_variable("data_dir") .. state.get_variable("duckdb_file")
		return {
			duckdb_cmd,
			path_db,
			"-cmd",
			".maxrows " .. tostring(limit),
			"-cmd",
			".nullvalue ''",
			"-c",
			query,
		}
	else
		return { duckdb_cmd, "-cmd", ".maxrows " .. tostring(limit), "-cmd", ".nullvalue ''", "-c", query }
	end
end

local function prepare_query(file, ext, mode, top_store_duckdb, limit, offset)
	local query

	if mode == "metadata" then
		query = METADATA_QUERIES[ext]
		query = string.format(query, file)
	elseif mode == "main_data" then
		if top_store_duckdb then
			query = DATA_QUERIES_STORE_DUCKDB[ext]
			query = string.format(query, TABLE_NAME, file, TABLE_NAME, limit, offset)
		else
			query = DATA_QUERIES[ext]
			query = string.format(query, file, limit, offset)
		end
	end

	return query, nil
end

function M.fetch_metadata(file, ext)
	local query, err = prepare_query(file, ext, "metadata", false, nil, nil)
	if err then
		return nil, err
	end

	-- Generate the duckdb command
	local cmd = generate_duckdb_command(query, false, 1000)

	-- Run the query
	local csv_text, err = run_query(cmd)
	if err then
		return nil, err
	end

	-- Parse Data
	local result, err = parser.parse_raw_text(csv_text)

	if not result then
		return nil, err
	end

	return { headers = result.headers, data = result.data, count_lines = result.count_lines }, nil
end

function M.fetch_main_data(file, ext, top_store_duckdb, limit)
	local query, err = prepare_query(file, ext, "main_data", top_store_duckdb, limit, 0)
	if err then
		return nil, err
	end

	-- Generate the duckdb command
	local cmd = generate_duckdb_command(query, top_store_duckdb, limit)

	-- Run the query
	local csv_text, err = run_query(cmd)
	if err then
		return nil, err
	end

	local result, err = parser.parse_raw_text(csv_text)

	if not result then
		return nil, err
	end

	return result.data, nil
end

--- Validate the user-provided SQL query.
--- Will check for the presence of the required 'FROM f' syntax.
--- @param query string The raw SQL query string provided by the user.
--- @return boolean success True if the query passes all validation checks.
--- @return string message A status or error message explaining the result.
local function validate_sql_query(query)
	-- Simple validation
	if query:match("^%s*$") then
		log.display_notify(3, "SQL query is empty!")
		return false, "SQL query is empty!"
	end

	if not string.find(query, "from%s+f") then
		return false, "Query must use the required syntax 'FROM f' to reference the file."
	end
	return true, "Query is valid!"
end

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

function M.execute_sql_query(opts, buf)
	local file = state.get_state("current_file")
	local limit = opts.limit
	local top_store_duckdb = opts.use_storage_duckdb
	local hl_enable = opts.hl.buffer.hl_enable

	-- Get SQL query from SQL buffer
	local sql_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local sql_query = table.concat(sql_lines, " ")

	-- Execute SQL query
	local new_query, err = prepare_user_query(file, sql_query, top_store_duckdb, limit, 0)
	if not new_query then
		return err
	end

	-- Generate the duckdb command
	local cmd = generate_duckdb_command(new_query, top_store_duckdb, limit)

	-- Run the query
	local out_data, err = run_query(cmd)
	if not out_data then
		return err
	end

	--Parse Data
	local result, err = parser.parse_raw_text(out_data)
	if not result then
		return err
	end

	-- Store last user query in state
	state.set_state("last_user_query", nil, sql_query)

	-- Update buffer data
	local buf_data = state.get_state("buffers", "buf_data")
	M.update_buffer(opts.hl.buffer.hl_enable, buf_data, result.data)

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
	if last_user_query then -- user has already executed a custom query
		query, err = prepare_user_query(file, last_user_query, top_store_duckdb, limit, offset)
	else
		if top_store_duckdb then
			query = "SELECT * FROM f"
			query = string.format("SELECT * FROM (%s) LIMIT %d OFFSET %d", query, limit, offset)
		else
			query = DATA_QUERIES[ext]
			query = string.format(query, file, limit, offset)
		end
	end

	-- Generate the duckdb command
	local cmd = generate_duckdb_command(query, top_store_duckdb, limit)
	local csv_text, err = run_query(cmd)
	if err then
		return nil, err
	end
	local result, err = parser.parse_raw_text(csv_text)

	if not result then
		return nil, err
	end

	state.set_state("num_page", nil, new_page)

	-- remove and update buffer data
	local buf_data = state.get_state("buffers", "buf_data")
	M.update_buffer(opts.hl.buffer.hl_enable, buf_data, result.data)
end

function M.update_buffer(hl_enable, buf_data, data)
	-- Update buffer data
	local formatted_lines = display.prepare_data(data)
	vim.api.nvim_buf_set_lines(buf_data, 0, -1, false, formatted_lines)

	if hl_enable then
		display.update_highlights(buf_data, formatted_lines)
	end
end

return M
