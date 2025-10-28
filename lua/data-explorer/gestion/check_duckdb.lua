local log = require("data-explorer.gestion.log")

local M = {}

---Checks if DuckDB is installed and available in the system PATH.
function M.is_duckdb_installed()
	return vim.fn.executable("duckdb") == 1
end

---Shows a warning message if DuckDB is not installed.
function M.check_duckdb_or_warn()
	if not M.is_duckdb_installed() then
		log.display_notify(
			4,
			"DuckDB is not installed or not in PATH. "
				.. "Please install it from https://duckdb.org/docs/installation/index"
		)
		return false
	end
	return true
end

return M
