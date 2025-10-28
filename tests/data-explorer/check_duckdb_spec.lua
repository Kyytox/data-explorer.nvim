local check_duckdb = require("data-explorer.gestion.check_duckdb")

describe("check_duckdb module", function()
	it("returns true when duckdb is executable", function()
		local original_executable = vim.fn.executable
		vim.fn.executable = function(_)
			return 1
		end

		assert.is_true(check_duckdb.is_duckdb_installed())

		vim.fn.executable = original_executable
	end)

	it("returns false when duckdb is not executable", function()
		local original_executable = vim.fn.executable
		vim.fn.executable = function(_)
			return 0
		end

		assert.is_false(check_duckdb.is_duckdb_installed())

		vim.fn.executable = original_executable
	end)

	it("shows a warning when duckdb is missing", function()
		local original_executable = vim.fn.executable
		local original_notify = vim.notify

		vim.fn.executable = function(_)
			return 0
		end
		local warned = false
		vim.notify = function(msg, level)
			warned = true
			assert.matches("DuckDB is not installed", msg)
			assert.equals(vim.log.levels.ERROR, level)
		end

		local result = check_duckdb.check_duckdb_or_warn()
		assert.is_false(result)
		assert.is_true(warned)

		vim.fn.executable = original_executable
		vim.notify = original_notify
	end)

	it("does not warn when duckdb is installed", function()
		local original_executable = vim.fn.executable
		local original_notify = vim.notify

		vim.fn.executable = function(_)
			return 1
		end
		local warned = false
		vim.notify = function()
			warned = true
		end

		local result = check_duckdb.check_duckdb_or_warn()
		assert.is_true(result)
		assert.is_false(warned)

		vim.fn.executable = original_executable
		vim.notify = original_notify
	end)
end)
