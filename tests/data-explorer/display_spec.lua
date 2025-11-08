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
			file_size = "10 MB",
		}
		local lines = display.prepare_metadata(file, metadata)
		assert.are.same({
			-- "📦 File: test.txt",
			"/tmp/test.txt",
			"File size: 10 MB",
			"Number of lines: 42",
			"",
			{
				column = "header1",
				type = "VARCHAR",
			},
			{
				column = "header2",
				type = "VARCHAR",
			},
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
				next_page = "J",
				prev_page = "K",
				toggle_sql = "s",
				focus_meta = "m",
				focus_data = "d",
			},
		}
		local lines = display.prepare_help(opts)
		assert.are.same({
			" q: Quit | r: Rotate | J: Next Page | K: Prev Page | m: Metadata | d: Data | s: SQL Query | b: Back ",
		}, lines)
	end)

	-- Test for SQL help
	it("prepare_sql_footer_help", function()
		local opts = {
			mappings = {
				execute_sql = "e",
				prev_history = "<Up>",
				next_history = "<Down>",
			},
		}
		local lines = display.prepare_sql_help(opts)
		assert.are.same({
			" <Up> - <Down>: Navigate History | e: Execute Query ",
		}, lines)
	end)
end)
