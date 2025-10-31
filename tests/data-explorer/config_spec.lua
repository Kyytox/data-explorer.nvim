local config_validation = require("data-explorer.gestion.config_validation")

describe("validate_options", function()
	local defaults = {
		limit = 250,
		layout = "vertical",
		files_types = {
			parquet = true,
			csv = true,
			tsv = true,
		},
		query_sql = {
			placeholder_sql = {
				"SELECT * FROM f LIMIT 1000;",
				"-- Warning: Large result could slow down / crash.",
				"-- To query the file, use 'f' as the table name.",
			},
		},
		telescope_opts = {
			finder = {
				exclude_dirs = { ".git", "node_modules", "__pycache__", "venv", ".venv" },
			},
		},
		window_opts = {
			max_height_metadata = 0.25,
			max_width_metadata = 0.25,
		},
		mappings = {
			quit = "q",
			rotate_layout = "r",
		},
	}

	it("checks limit", function()
		local opts = { limit = -5 }
		local err = config_validation.check_limit(defaults, opts)
		assert.are.equal("limit must be a positive number. Reverting to default.", err)
		assert.are.equal(defaults.limit, opts.limit)

		opts.limit = 100
		err = config_validation.check_limit(defaults, opts)
		assert.is_nil(err)
	end)

	it("checks layout", function()
		local opts = { layout = "diagonal" }
		local err = config_validation.check_layout(defaults, opts)
		assert.are.equal('layout must be "vertical" or "horizontal". Reverting to default.', err)
		assert.are.equal(defaults.layout, opts.layout)

		opts.layout = "horizontal"
		err = config_validation.check_layout(defaults, opts)
		assert.is_nil(err)
	end)

	it("checks placeholder_sql", function()
		local opts = { query_sql = { placeholder_sql = "not a table" } }
		local err = config_validation.check_placeholder_sql(defaults, opts)
		assert.are.equal("placeholder_sql must be a table. Reverting to default.", err)
		assert.are.same(defaults.query_sql.placeholder_sql, opts.query_sql.placeholder_sql)

		opts.query_sql.placeholder_sql = {
			"SELECT name FROM f;",
		}
		err = config_validation.check_placeholder_sql(defaults, opts)
		assert.is_nil(err)
	end)

	it("checks max metadata dimensions", function()
		local opts = { window_opts = { max_height_metadata = 1.5, max_width_metadata = -0.2 } }
		local err = config_validation.check_max_metadata_dimensions(defaults, opts)
		assert.are.equal(
			"max_height_metadata and max_width_metadata must be numbers between 0 and 1. Reverting to default..",
			err
		)
		assert.are.equal(defaults.window_opts.max_height_metadata, opts.window_opts.max_height_metadata)
		assert.are.equal(defaults.window_opts.max_width_metadata, opts.window_opts.max_width_metadata)

		opts.window_opts.max_height_metadata = 0.5
		opts.window_opts.max_width_metadata = 0.8
		err = config_validation.check_max_metadata_dimensions(defaults, opts)
		assert.is_nil(err)
	end)

	it("checks files_types", function()
		local opts = { files_types = "not a table" }
		local err = config_validation.check_files_types(defaults, opts)
		assert.are.equal("files_types must be a table. Reverting to default.", err)
		assert.are.same(defaults.files_types, opts.files_types)

		opts.files_types = {
			parquet = true,
			xml = true, -- unsupported type
		}
		err = config_validation.check_files_types(defaults, opts)
		-- get first sentence (.)
		assert.are.equal("Unsupported file type: xml.", string.match(err, "^[^.]+%."))
		assert.are.same({ parquet = true, xml = false }, opts.files_types)

		opts.files_types = {
			csv = true,
			tsv = true,
		}
		err = config_validation.check_files_types(defaults, opts)
		assert.is_nil(err)
		assert.are.same({ csv = true, tsv = true }, opts.files_types)
	end)

	it("checks telescope finder exclude_dirs", function()
		local opts = { telescope_opts = { finder = { exclude_dirs = "not a table" } } }
		local err = config_validation.check_exclude_dirs(defaults, opts)
		assert.are.equal("exclude_dirs must be a table. Reverting to default.", err)
		assert.are.same(defaults.telescope_opts.finder.exclude_dirs, opts.telescope_opts.finder.exclude_dirs)

		opts.telescope_opts.finder.exclude_dirs = { ".git", "node_modules" }
		err = config_validation.check_exclude_dirs(defaults, opts)
		assert.is_nil(err)
		assert.are.same({ ".git", "node_modules" }, opts.telescope_opts.finder.exclude_dirs)
	end)

	it("checks mappings", function()
		local opts = { mappings = { rotate_layout = true } }
		local err = config_validation.check_mappings(defaults, opts)
		assert.are.equal("Mapping for rotate_layout must be a string. Reverting to default.", err)
		assert.are.equal(defaults.mappings.rotate_layout, opts.mappings.rotate_layout)

		opts = { mappings = { quit = 5 } }
		err = config_validation.check_mappings(defaults, opts)
		assert.are.equal("Mapping for quit must be a string. Reverting to default.", err)
		assert.are.equal(defaults.mappings.quit, opts.mappings.quit)

		opts.mappings.quit = "x"
		opts.mappings.rotate_layout = "y"
		err = config_validation.check_mappings(defaults, opts)
		assert.is_nil(err)
		assert.are.equal("x", opts.mappings.quit)
		assert.are.equal("y", opts.mappings.rotate_layout)
	end)
end)
