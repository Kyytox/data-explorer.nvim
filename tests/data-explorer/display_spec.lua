local display = require("data-explorer.ui.display")

describe("Tests Display module", function()
	-- Test for prepare_metadata
	it("prepare_metadata", function()
		local file = "/tmp/test.txt"
		local metadata = {
			headers = { "column", "type" },
			data = {
				{ column = "header1", type = "VARCHAR" },
				{ column = "header2", type = "VARCHAR" },
			},
			count_lines = 42,
		}
		local lines = display.prepare_metadata(file, metadata)
		assert.are.same({
			-- "📦 File: test.txt",
			"/tmp/test.txt",
			"Number of lines: 42",
			"",
			"column  │type    ",
			"────────┼────────",
			"header1 │VARCHAR ",
			"header2 │VARCHAR ",
		}, lines)
	end)

	-- Test for prepare_metadata with zero lines
	it("prepare_metadata with 0 lines", function()
		local file = "/tmp/test.txt"
		local metadata = {
			headers = { "column", "type" },
			data = {
				{ column = "header1", type = "VARCHAR" },
				{ column = "header2", type = "VARCHAR" },
			},
			count_lines = 0,
		}
		local lines = display.prepare_metadata(file, metadata)
		assert.are.same({
			-- "📦 File: test.txt",
			"/tmp/test.txt",
			"",
			"",
			"No data in the file.",
		}, lines)
	end)

	-- Test for prepare_help
	it("prepare_help", function()
		local opts = {
			mappings = {
				quit = "q",
				rotate_layout = "r",
				back = "b",
				toggle_sql = "s",
				focus_meta = "m",
				focus_data = "d",
			},
		}
		local lines = display.prepare_help(opts)
		assert.are.same({
			"q: Quit | r: Rotate | b: Back file selection | s: SQL Query | m: Metadata | d: Data",
		}, lines)
	end)

	-- Test for prepare_sql_help
	it("prepare_sql_help", function()
		local opts = {
			mappings = {
				toggle_sql = "t",
				execute_sql = "e",
			},
		}
		local lines = display.prepare_sql_help(opts)
		assert.are.same({
			"Ex: SELECT * FROM f WHERE ... | t: Hide | e: Execute",
		}, lines)
	end)

	-- Test for prepare_data
	it("prepare_data", function()
		local headers = { "Name", "Age" }
		local data = {
			{ Name = "Alice", Age = "30" },
			{ Name = "Bob", Age = "25" },
			{ Name = "Charlie", Age = "40" },
		}
		local lines = display.prepare_data(headers, data)

		assert.are.same("Name    │Age ", lines[1])
		assert.are.same("────────┼────", lines[2])
		assert.are.same("Alice   │30  ", lines[3])
		assert.are.same("Bob     │25  ", lines[4])
		assert.are.same("Charlie │40  ", lines[5])
	end)
end)
