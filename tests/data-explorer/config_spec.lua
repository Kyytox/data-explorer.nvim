local config = require("data-explorer.gestion.config")

describe("validate_options", function()
	local defaults
	before_each(function()
		defaults = {
			limit = 1000,
			layout = "vertical",
			window_opts = { border = "rounded" },
			placeholder_sql = {
				"SELECT * FROM f LIMIT 1000;",
				"-- Warning: Large result could slow down / crash.",
				"-- To query the file, use 'f' as the table name.",
			},
			files_types = {
				parquet = true,
				csv = true,
				tsv = true,
			},
		}
	end)

	it("reverts invalid limit", function()
		local opts = { limit = -1 }
		local msg = config.validate_options(opts)
		assert.equals(config.defaults.limit, opts.limit)
		assert.matches("limit must be a positive number", msg)
	end)

	it("reverts invalid layout", function()
		local opts = { limit = 10, layout = "diagonal" }
		local msg = config.validate_options(opts)
		assert.equals(config.defaults.layout, opts.layout)
		assert.matches("layout must be", msg)
	end)

	it("reverts invalid placeholder_sql (need a table)", function()
		local opts = {
			limit = 10,
			layout = "vertical",
			placeholder_sql = "SELECT * FROM f;",
			files_types = defaults.files_types,
		}
		local msg = config.validate_options(opts)
		assert.equals(config.defaults.placeholder_sql[1], defaults.placeholder_sql[1])
		assert.equals(config.defaults.placeholder_sql[2], defaults.placeholder_sql[2])
		assert.equals(config.defaults.placeholder_sql[3], defaults.placeholder_sql[3])
		assert.matches("placeholder_sql must be a table", msg)
	end)

	it("reverts invalid files_types types", function()
		local opts = { limit = 10, layout = "vertical", files_types = "csv" }
		local msg = config.validate_options(opts)
		assert.equals(config.defaults.files_types[1], opts.files_types[1])
		assert.matches("files_types must be a table", msg)
	end)

	it("reverts invalid files_types values", function()
		local opts = {
			limit = 10,
			layout = "vertical",
			files_types = { csv = true, xml = true },
			placeholder_sql = defaults.placeholder_sql,
		}
		local msg = config.validate_options(opts)
		print(vim.inspect(msg))
		assert.matches("Unsupported file type: xml", msg)
	end)
end)
