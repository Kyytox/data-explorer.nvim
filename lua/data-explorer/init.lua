-- Modules
local config = require("data-explorer.gestion.config")
local utils = require("data-explorer.core.utils")
local picker = require("data-explorer.ui.picker")
local core = require("data-explorer.core.core")
local check_focus = require("data-explorer.gestion.check_focus")
local check_duckdb = require("data-explorer.gestion.check_duckdb")
local log = require("data-explorer.gestion.log")

local M = {}

--- Setup Data Explorer
--- @param opts table|nil: User configuration options.
function M.setup(opts)
	-- Check DuckDB installation
	if not check_duckdb.check_duckdb_or_warn() then
		return
	end

	config.setup(opts)
	log.setup() -- Decomment logging setup for dev

	-- Launch Data Explorer
	vim.api.nvim_create_user_command("DataExplorer", function()
		M.data_explorer()
	end, { desc = "Open Data Explorer", nargs = 0 })

	-- Launch Data Explorer for current files
	vim.api.nvim_create_user_command("DataExplorerFile", function()
		M.data_explorer_file()
	end, { desc = "Open Data Explorer for current file", nargs = 0 })
end

--- Set Autocommands for Data Explorer
local function set_autocommands()
	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		callback = check_focus.check_focus_and_close,
		group = vim.api.nvim_create_augroup("DataExplorerGroup", { clear = true }),
	})
end

--- Main function Data Explorer
function M.data_explorer()
	-- Check DuckDB installation
	if not check_duckdb.check_duckdb_or_warn() then
		return
	end

	local opts = config.get()

	-- exctract file types from opts.files_types
	local files_types = utils.aggregate_file_types(opts)
	log.debug("Accepted file types: " .. table.concat(files_types, ", "))

	-- Set Autocommands
	set_autocommands()

	-- Find all files with accepted extensions
	-- local files = utils.get_files_in_working_directory(files_types)

	-- if #files == 0 then
	-- 	local type_str = table.concat(files_types, ", ")
	-- 	log.display_notify(3, "No files found with extensions: " .. type_str)
	-- 	return
	-- end

	-- Launch Data Explorer
	picker.pickers_files(opts, files_types)
end

--- Data Explorer File
function M.data_explorer_file()
	-- Check DuckDB installation
	if not check_duckdb.check_duckdb_or_warn() then
		return
	end

	local opts = config.get()

	-- exctract file types from opts.files_types
	local files_types = utils.aggregate_file_types(opts)

	-- Set Autocommands
	set_autocommands()

	-- Get current buffer file
	local file = vim.api.nvim_buf_get_name(0)

	if file == nil or file == "" then
		log.display_notify(3, "No file found in current buffer")
		return
	end

	-- Check if file is an accepted file type
	-- Use the helper function with the configured file types
	if not utils.is_accepted_file_type(file, files_types) then
		local type_str = table.concat(files_types, ", ")
		log.display_notify(3, "Current file is not an accepted file type. \nAccepted types: " .. type_str)
		return
	end

	-- Launch Data Explorer
	core.render(opts, file)
end

return M
