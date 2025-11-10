local duckdb = require("data-explorer.core.duckdb")
local plenary = require("plenary")

describe("DuckDB Performance Tests", function()
	local lst_files = {
		-- "/media/kytox/Dev/data-explorer.nvim/tests/data_test/nasa_small_file.tsv",
		-- "/media/kytox/Dev/data-explorer.nvim/tests/data_test/nasa_small_file.csv",
		-- "/media/kytox/Dev/data-explorer.nvim/tests/data_test/nasa_small_file.parquet",
		-- "/media/kytox/Dev/data-explorer.nvim/tests/data_test/nasa_big_file.tsv",
		"/media/kytox/Dev/data-explorer.nvim/tests/data_test/nasa_big_file.csv",
		"/media/kytox/Dev/data-explorer.nvim/tests/data_test/nasa_big_file.parquet",
	}

	local avergage_time = function(lst_times, limit, mode)
		local total_time = 0
		local min_time = math.huge
		local max_time = 0

		-- get all infos according unique file_path
		local files = {}
		for _, info in ipairs(lst_times) do
			files[info.file_path] = true
		end

		for file_path, _ in pairs(files) do
			total_time = 0
			min_time = math.huge
			max_time = 0
			local count = 0

			for _, t in ipairs(lst_times) do
				if t.file_path == file_path then
					total_time = total_time + t.time
					count = count + 1
					if t.time < min_time then
						min_time = t.time
					end
					if t.time > max_time then
						max_time = t.time
					end
				end
			end

			print(
				string.format(
					"Avg Time: %.5f s | File: %s | Mode: %s | Limit: %d |  Min Time: %.5f s | Max Time: %.5f s  ",
					total_time / count,
					file_path:match("^.+/(.+)$"),
					mode,
					limit,
					min_time,
					max_time
				)
			)
		end
	end

	local test_run = function(lst_files, limit, mode)
		print("---------------------------------------------------")
		local lst_times = {}
		local err

		for _, file_path in ipairs(lst_files) do
			local iterations = 5
			for i = 1, iterations do
				-- local start = os.clock()

				local file = plenary.path.new(file_path):absolute()
				local ext = file:match("^.+(%..+)$"):sub(2)

				local result, err = duckdb.fetch_main_data(file, ext, true, limit)
				-- local result, err = duckdb.fetch_main_data(file, ext, false, limit)

				-- get last lilne result
				-- You need to decomment timer in duckdb.lua in cmd duckdb
				local last_line = result[#result]

				-- get number after 'real' in last line
				local elapsed = tonumber(last_line:match("real%s+([%d%.]+)"))

				-- local finish = os.clock()
				-- local elapsed = finish - start
				local infos = { file_path = file, mode = mode, limit = limit, iteration = i, time = elapsed }
				table.insert(lst_times, infos)
				i = i + 1

				-- break 1 second between iterations
				vim.wait(700)

				-- print(string.format("SQL query executed in: %.5f seconds for file: %s", elapsed, file_path))
			end
		end
		avergage_time(lst_times, limit, mode)
	end

	it("Performance Test - Main Data 50 rows", function()
		test_run(lst_files, 50, "main_data")
	end)

	-- it("Performance Test - Main Data 1000 rows", function()
	-- 	test_run(lst_files, 1000, "main_data")
	-- end)

	-- it("Performance Test - Main Data 5000 rows", function()
	-- 	test_run(lst_files, 5000, "main_data")
	-- end)

	-- it("Performance Test - Main Data 20000 rows", function()
	-- 	test_run(lst_files, 20000, "main_data")
	-- end)
end)

-- describe("DuckDB Performance Tests", function()
-- 	local lst_files
--
-- 	before_each(function()
-- 		local type = { ".parquet", ".csv", ".tsv" }
-- 		lst_files = utils.get_files_in_working_directory(type)
-- 	end)
--
-- 	local avergage_time = function(lst_times)
-- 		local total_time = 0
-- 		local min_time = math.huge
-- 		local max_time = 0
-- 		for _, t in ipairs(lst_times) do
-- 			total_time = total_time + t
-- 			if t < min_time then
-- 				min_time = t
-- 			end
-- 			if t > max_time then
-- 				max_time = t
-- 			end
-- 		end
-- 		print(string.format("Average execution time: %.5f seconds", total_time / #lst_times))
-- 		print(string.format("Minimum  time: %.5f seconds", min_time))
-- 		print(string.format("Maximum  time: %.5f seconds", max_time))
-- 		print("---------------------------------------------------")
-- 	end
--
-- 	local test_run = function(SQL, lst_files, delim, limit, exclude, mode)
-- 		local lst_times = {}
-- 		local err
--
-- 		for _, file_path in ipairs(lst_files) do
-- 			if not string.find(file_path, exclude) or exclude == "" then
-- 				local start = os.clock()
--
-- 				local file = plenary.path.new(file_path):absolute()
-- 				local ext = file:match("^.+(%..+)$")
--
-- 				local query
-- 				if limit == nil then
-- 					query = string.format(SQL[ext:sub(2)], file)
-- 				else
-- 					query = string.format(SQL[ext:sub(2)], file, limit)
-- 				end
--
-- 				local out
-- 				local success
-- 				if mode == "standard" then
-- 					local full_cmd = string.format('%s -csv -c "%s"', "duckdb", query:gsub('"', '\\"'))
-- 					local result = io.popen(full_cmd)
-- 					out = result:read("*a")
-- 					success = result:close() ~= nil
-- 				else
-- 					local full_cmd = { "duckdb", "-csv", "-c", query }
-- 					local result = vim.system(full_cmd, { text = true }):wait()
-- 					out = result.stdout
-- 					success = result.code == 0
-- 				end
--
-- 				result, err = parser.parse_csv(out, delim)
--
-- 				local finish = os.clock()
-- 				local elapsed = finish - start
-- 				table.insert(lst_times, elapsed)
-- 				-- print(string.format("SQL query executed in: %.5f seconds for file: %s", elapsed, file_path))
-- 			end
-- 		end
-- 		avergage_time(lst_times)
-- 	end
--
-- 	it("Metadata without COPY with delimiter ,", function()
-- 		local SQL = {
-- 			parquet = [[
--           SELECT
--           path_in_schema AS Column,
--           type AS Type,
--           num_values AS Count,
--           stats_min AS Min,
--           stats_max AS Max,
--           stats_null_count AS Nulls
--           FROM parquet_metadata('%s');
--         ]],
-- 			csv = [[
-- 	       CREATE TEMP TABLE tmp AS
-- 	       SELECT * FROM read_csv_auto('%s', auto_detect=true, sample_size=-1, ALL_VARCHAR=FALSE);
--          WITH total AS (SELECT COUNT(*) AS total_rows FROM tmp)
-- 	       SELECT
-- 	         name AS Column,
-- 	         type AS Type,
-- 	         (SELECT total_rows FROM total) AS Count
-- 	       FROM pragma_table_info('tmp');
--         ]],
-- 			tsv = [[
--         CREATE TEMP TABLE tmp AS
--         SELECT * FROM read_csv_auto('%s', auto_detect=true, sep='\t', sample_size=-1, ALL_VARCHAR=FALSE);
--         WITH total AS (SELECT COUNT(*) AS total_rows FROM tmp)
--         SELECT
--           name AS Column,
--           type AS Type,
--           (SELECT total_rows FROM total) AS Count
--         FROM pragma_table_info('tmp');
--         ]],
-- 			json = [[
--         CREATE TEMP TABLE tmp AS SELECT * FROM read_json_auto('%s', auto_detect=true);
--         WITH total AS (SELECT COUNT(*) AS total_rows FROM tmp)
--         SELECT
--           name AS Column,
--           replace(type, ',', ';') AS Type,
--           dflt_value AS DefaultValue,
--           pk AS PrimaryKey,
--           (SELECT total_rows FROM total) AS Count
--         FROM pragma_table_info('tmp');
--         ]],
-- 		}
-- 		test_run(SQL, lst_files, ",", nil, "", "standard")
-- 		test_run(SQL, lst_files, ",", nil, "", "custom") -- worst
-- 	end)
--
-- 	it("Metadata with COPY with delimiter |", function()
-- 		local SQL = {
-- 			parquet = [[
--       COPY(
--           SELECT
--           path_in_schema AS Column,
--           type AS Type,
--           num_values AS Count,
--           stats_min AS Min,
--           stats_max AS Max,
--           stats_null_count AS Nulls
--           FROM parquet_metadata('%s')
--         ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--         ]],
-- 			csv = [[
-- 	       CREATE TEMP TABLE tmp AS
-- 	       SELECT * FROM read_csv_auto('%s', auto_detect=true, sample_size=-1, ALL_VARCHAR=FALSE);
--
--          COPY(
--             WITH total AS (SELECT COUNT(*) AS total_rows FROM tmp)
--             SELECT
--               name AS Column,
--               type AS Type,
--               (SELECT total_rows FROM total) AS Count
--             FROM pragma_table_info('tmp')
--          ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--         ]],
-- 			tsv = [[
--         CREATE TEMP TABLE tmp AS
--         SELECT * FROM read_csv_auto('%s', auto_detect=true, sep='\t', sample_size=-1, ALL_VARCHAR=FALSE);
--
--           COPY(
--               WITH total AS (
--                 SELECT COUNT(*) AS total_rows FROM tmp
--               )
--               SELECT
--                 name AS Column,
--                 type AS Type,
--                 (SELECT total_rows FROM total) AS Count
--               FROM pragma_table_info('tmp')
--         ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--         ]],
-- 			json = [[
--         CREATE TEMP TABLE tmp AS SELECT * FROM read_json_auto('%s', auto_detect=true);
--         COPY(
--         WITH total AS (SELECT COUNT(*) AS total_rows FROM tmp)
--         SELECT
--           name AS Column,
--           replace(type, ',', ';') AS Type,
--           dflt_value AS DefaultValue,
--           pk AS PrimaryKey,
--           (SELECT total_rows FROM total) AS Count
--         FROM pragma_table_info('tmp')
--         ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--         ]],
-- 		}
-- 		test_run(SQL, lst_files, "|", nil, "", "standard") -- best
-- 		-- test_run(SQL, lst_files, "|", nil, "", "custom")
-- 	end)
--
-- 	it("Data without COPY with delimiter ,", function()
-- 		local SQL = {
-- 			parquet = "SELECT * FROM read_parquet('%s') LIMIT %d;",
-- 			csv = "SELECT * FROM read_csv_auto('%s') LIMIT %d;",
-- 			tsv = "SELECT * FROM read_csv_auto('%s', sep='\t') LIMIT %d;",
-- 			json = "SELECT * FROM read_json('%s') LIMIT %d;",
-- 		}
-- 		test_run(SQL, lst_files, ",", 30000, "large", "standard")
-- 		test_run(SQL, lst_files, ",", 30000, "large", "custom") -- worst
-- 	end)
--
-- 	it("Data with COPY with delimiter |", function()
-- 		local SQL = {
-- 			parquet = [[
--         COPY(
--           SELECT * FROM read_parquet('%s') LIMIT %d
--         ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--       ]],
-- 			csv = [[
--           COPY(
--             SELECT * FROM read_csv_auto('%s') LIMIT %d
--           ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--       ]],
-- 			tsv = [[
--           COPY(
--             SELECT * FROM read_csv_auto('%s', sep='\t') LIMIT %d
--           ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--       ]],
-- 			json = [[
--           COPY(
--             SELECT * FROM read_json('%s') LIMIT %d
--           ) TO STDOUT WITH (FORMAT CSV, HEADER, DELIMITER '|', QUOTE '"');
--       ]],
-- 		}
-- 		test_run(SQL, lst_files, "|", 30000, "large", "standard")
-- 		-- test_run(SQL, lst_files, "|", 30000, "large", "custom") -- best
-- 	end)
-- end)
