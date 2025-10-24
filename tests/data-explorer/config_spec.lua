local config = require("data-explorer.gestion.config")

describe("apply_defaults", function()
	it("fills missing keys from defaults", function()
		local defaults = { limit = 1000, layout = "vertical" }

		local user1 = { limit = nil, layout = nil }
		local merged = config.apply_defaults(user1, defaults)
		assert.equals(1000, merged.limit)
		assert.equals("vertical", merged.layout)
	end)

	it("keeps user-defined keys", function()
		local user = { window_opts = { border = "single" } }
		local defaults = { window_opts = { border = "rounded", hide_window_help = true } }
		local merged = config.apply_defaults(user, defaults)
		assert.equals("single", merged.window_opts.border)
		assert.equals(true, merged.window_opts.hide_window_help)
	end)
end)

describe("validate_options", function()
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

	it("reverts invalid files_types types", function()
		local opts = { limit = 10, layout = "vertical", files_types = "csv" }
		local msg = config.validate_options(opts)
		assert.equals(config.defaults.files_types[1], opts.files_types[1])
		assert.matches("files_types must be a table", msg)
	end)

	it("reverts invalid files_types values", function()
		local opts = { limit = 10, layout = "vertical", files_types = { csv = true, xml = true } }
		local msg = config.validate_options(opts)
		print(vim.inspect(msg))
		assert.matches("Unsupported file type: xml", msg)
	end)
end)
