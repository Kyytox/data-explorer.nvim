local config = require("data-explorer.gestion.config")

describe("validate_options", function()
	local defaults = config.defaults

	it("reverts invalid limit", function()
		local opts = { limit = -1 }
		local msg = config.validate_options(opts)
		assert.equals(defaults.limit, opts.limit)
		assert.matches("limit must be a positive number", msg)
	end)

	it("reverts invalid layout", function()
		local opts = { limit = 10, layout = "diagonal" }
		local msg = config.validate_options(opts)
		assert.equals(defaults.layout, opts.layout)
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
		assert.equals(defaults.placeholder_sql[1], defaults.placeholder_sql[1])
		assert.equals(defaults.placeholder_sql[2], defaults.placeholder_sql[2])
		assert.equals(defaults.placeholder_sql[3], defaults.placeholder_sql[3])
		assert.matches("placeholder_sql must be a table", msg)
	end)

	it("reverts invalid files_types types", function()
		local opts = { limit = 10, layout = "vertical", files_types = "csv" }
		local msg = config.validate_options(opts)
		assert.equals(defaults.files_types[1], opts.files_types[1])
		assert.matches("files_types must be a table", msg)
	end)

	it("reverts invalid files_types values", function()
		local opts = {
			limit = 10,
			layout = "vertical",
			files_types = { csv = true, xml = true },
			placeholder_sql = defaults.placeholder_sql,
			window_opts = defaults.window_opts,
		}
		local msg = config.validate_options(opts)
		assert.matches("Unsupported file type: xml", msg)
	end)

	it("reverts max_height_metadata, max_width_metadata to defaults if invalid", function()
		local opts = {
			limit = 10,
			layout = "vertical",
			window_opts = {
				border = "rounded",
				max_height_metadata = 1.5,
				max_width_metadata = -0.2,
			},
			placeholder_sql = defaults.placeholder_sql,
			files_types = defaults.files_types,
		}
		local msg = config.validate_options(opts)
		assert.equals(defaults.window_opts.max_height_metadata, opts.window_opts.max_height_metadata)
		assert.equals(defaults.window_opts.max_width_metadata, opts.window_opts.max_width_metadata)
		assert.matches(
			"max_height_metadata and max_width_metadata must be numbers between 0 and 1. Reverting to defaults.",
			msg
		)
	end)
end)
