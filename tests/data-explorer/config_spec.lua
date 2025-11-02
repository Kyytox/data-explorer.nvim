local config_validation = require("data-explorer.gestion.config_validation")

describe("valid_user_options", function()
	local defaults = {
		limit = 250, -- Maximum number of rows to fetch
		layout = "vertical", -- Vertical or horizontal
		files_types = {
			parquet = true,
			csv = true,
			tsv = true,
		},

		-- UI/Telescope options
		telescope_opts = {
			layout_strategy = "vertical",
			layout_config = {
				height = 0.4,
				width = 0.9,
				preview_cutoff = 1,
				preview_height = 0.5, -- Used for vertical layout
				preview_width = 0.4, -- Used for horizontal layout
			},
			finder = {
				include_hidden = false, -- Show hidden files
				exclude_dirs = { ".git", "node_modules", "__pycache__", "venv", ".venv" },
			},
		},

		-- Floating window options for main display windows
		window_opts = {
			border = "rounded",
			max_height_metadata = 0.25,
			max_width_metadata = 0.25,
		},

		-- Query SQL
		query_sql = {
			-- Lines displayed in the SQL window when opened
			placeholder_sql = {
				"SELECT * FROM f LIMIT 1000;",
				"-- Warning: Large result could slow down / crash.",
				"-- To query the file, use 'f' as the table name.",
			},
		},

		-- Key mappings
		mappings = {
			quit = "q", -- Close the main UI
			back = "<BS>", -- Go back to file selection
			focus_meta = "1", -- Focus the metadata window
			focus_data = "2", -- Focus the data window
			toggle_sql = "3", -- Toggle the SQL query window
			rotate_layout = "r", -- Rotate the layout
			execute_sql = "e", -- Execute the SQL query
		},

		-- Highlight colors
		hl = {
			windows = {
				bg = "#11111b",
				fg = "#cdd6f4",
				title = "#f5c2e7",
				footer = "#a6e3a1",
				sql_fg = "#89b4fa",
				sql_bg = "#1e1e2e",
				sql_err_fg = "#f38ba8",
				sql_err_bg = "#3b1d2a",
			},
			buffer = {
				hl_enable = true,
				header = "white",
				col1 = "#f38ba8",
				col2 = "#89b4fa",
				col3 = "#a6e3a1",
				col4 = "#f9e2af",
				col5 = "#cba6f7",
				col6 = "#94e2d5",
				col7 = "#f5c2e7",
				col8 = "#89b4fa",
				col9 = "#a6e3a1",
			},
		},
	}
	it("checks limit", function()
		local opts = { limit = -5 }
		local err = config_validation.check_limit(defaults, opts, "limit")
		assert.are.equal(1, #err)
		assert.are.equal(defaults.limit, opts.limit)

		opts.limit = 100
		err = config_validation.check_limit(defaults, opts, "limit")
		assert.are.equal(0, #err)
	end)

	it("checks layout", function()
		local opts = { layout = "diagonal" }
		local err = config_validation.check_layout(defaults, opts, "layout")
		assert.are.equal(1, #err)
		assert.are.equal(defaults.layout, opts.layout)

		opts.layout = "horizontal"
		err = config_validation.check_layout(defaults, opts, "layout")
		assert.are.equal(0, #err)
	end)

	it("checks placeholder_sql", function()
		local opts = { query_sql = { placeholder_sql = "not a table" } }
		local err = config_validation.check_query_sql(defaults, opts, "query_sql")
		assert.are.equal(1, #err)
		assert.are.same(defaults.query_sql.placeholder_sql, opts.query_sql.placeholder_sql)

		opts.query_sql.placeholder_sql = {
			"SELECT name FROM f;",
		}
		err = config_validation.check_query_sql(defaults, opts, "query_sql")
		assert.are.equal(0, #err)
	end)
	--
	it("checks max metadata dimensions", function()
		local opts = { window_opts = { border = "rounded", max_height_metadata = 1.5, max_width_metadata = -0.2 } }
		local err = config_validation.check_window_opts(defaults, opts, "window_opts")
		assert.are.equal(1, #err)
		assert.are.equal(defaults.window_opts.max_height_metadata, opts.window_opts.max_height_metadata)
		assert.are.equal(defaults.window_opts.max_width_metadata, opts.window_opts.max_width_metadata)

		opts.window_opts.max_height_metadata = 0.5
		opts.window_opts.max_width_metadata = 0.3
		err = config_validation.check_window_opts(defaults, opts, "window_opts")
		assert.are.equal(0, #err)
	end)

	it("checks files_types", function()
		local opts = { files_types = "not a table" }
		local err = config_validation.check_files_types(defaults, opts, "files_types")
		assert.are.equal(1, #err)
		assert.are.same(defaults.files_types, opts.files_types)

		opts.files_types = {
			parquet = true,
			xml = true, -- unsupported type
		}
		err = config_validation.check_files_types(defaults, opts, "files_types")
		assert.are.equal(1, #err)
		assert.are.same({ parquet = true, xml = false }, opts.files_types)

		opts.files_types = {
			csv = true,
			tsv = true,
		}
		err = config_validation.check_files_types(defaults, opts, "files_types")
		assert.are.equal(0, #err)
		assert.are.same({ csv = true, tsv = true }, opts.files_types)
	end)

	it("checks telescope finder exclude_dirs", function()
		local opts = {
			telescope_opts = {
				layout_strategy = "vertical",
				layout_config = {
					height = 4,
				},
				finder = { exclude_dirs = "not a table" },
			},
		}
		local err = config_validation.check_telescope_opts(defaults, opts, "telescope_opts")
		assert.are.equal(3, #err)
		assert.are.same(defaults.telescope_opts.finder.exclude_dirs, opts.telescope_opts.finder.exclude_dirs)

		opts.telescope_opts.finder.exclude_dirs = { ".git", "node_modules" }
		err = config_validation.check_telescope_opts(defaults, opts, "telescope_opts")
		assert.are.equal(0, #err)
		assert.are.same({ ".git", "node_modules" }, opts.telescope_opts.finder.exclude_dirs)
	end)

	it("checks mappings", function()
		local opts = { mappings = { rotate_layout = true } }
		local err = config_validation.check_mappings(defaults, opts, "mappings")
		assert.are.equal(1, #err)
		assert.are.equal(defaults.mappings.rotate_layout, opts.mappings.rotate_layout)

		opts = { mappings = { quit = 5 } }
		err = config_validation.check_mappings(defaults, opts, "mappings")
		assert.are.equal(1, #err)
		assert.are.equal(defaults.mappings.quit, opts.mappings.quit)

		opts.mappings.quit = "x"
		opts.mappings.rotate_layout = "y"
		err = config_validation.check_mappings(defaults, opts, "mappings")
		assert.are.equal(0, #err)
		assert.are.equal("x", opts.mappings.quit)
		assert.are.equal("y", opts.mappings.rotate_layout)
	end)

	it("checks hl window colors", function()
		local opts = {
			hl = {
				windows = {
					bg = 123,
					sql_err_bg = "#3b1d2a",
				},
				buffer = {
					hl_enable = "true",
					header = {},
					col1 = "#f38ba8",
					col2 = "#89b4fa",
				},
			},
		}
		local err = config_validation.check_highlight(defaults, opts, "hl")
		assert.are.equal(3, #err)
		assert.are.equal(defaults.hl.windows.bg, opts.hl.windows.bg)
		assert.are.equal(defaults.hl.buffer.hl_enable, opts.hl.buffer.hl_enable)
		assert.are.equal(defaults.hl.buffer.header, opts.hl.buffer.header)
		opts.hl.windows.bg = "#222233"
		opts.hl.buffer.hl_enable = false
		opts.hl.buffer.header = "yellow"
		err = config_validation.check_highlight(defaults, opts, "hl")
		assert.are.equal(0, #err)
		assert.are.equal("#222233", opts.hl.windows.bg)
		assert.are.equal(false, opts.hl.buffer.hl_enable)
		assert.are.equal("yellow", opts.hl.buffer.header)
	end)
end)
