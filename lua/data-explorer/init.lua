-- Modules
local config = require("data-explorer.gestion.config")
local utils = require("data-explorer.core.utils")
local picker = require("data-explorer.ui.picker")
local core = require("data-explorer.core.core")
local check_focus = require("data-explorer.gestion.check_focus")
local check_duckdb = require("data-explorer.gestion.check_duckdb")
local log = require("data-explorer.gestion.log")

local M = {}

local AUGROUP = vim.api.nvim_create_augroup("DataExplorerGroup", { clear = true })

--- Setup
--- @param opts table|nil: User configuration options.
function M.setup(opts)
	-- Setup configuration
	config.setup(opts)
	-- log.setup_dev()

	-- Create cache files for process
	utils.create_cache_files(opts)
end

--- Set Autocommands for Data Explorer
local function set_autocommands()
	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		callback = check_focus.check_focus_and_close,
		group = AUGROUP,
		desc = "Auto close Data Explorer on focus lost",
	})
end

--- Prepare Environment
--- @return table|nil: Configuration options.
--- @return table|nil: Accepted file types.
local function prepare_environment()
	-- Check DuckDB installation
	if not check_duckdb.check_duckdb_or_warn() then
		return
	end

	-- Get configuration options
	local opts = config.get()

	-- Exctract file types
	local files_types = utils.aggregate_file_types(opts)

	-- Set Autocommands
	set_autocommands()

	return opts, files_types
end

--- Main function Data Explorer
function M.data_explorer()
	local opts, files_types = prepare_environment()
	if not opts then
		return
	end

	-- Launch Data Explorer
	picker.pickers_files(opts, files_types)
end

--- Data Explorer File
function M.data_explorer_file()
	local opts, files_types = prepare_environment()
	if not opts then
		return
	end

	-- Get current buffer file
	local file = vim.api.nvim_buf_get_name(0)

	if file == nil or file == "" then
		log.display_notify(3, "No file found in current buffer")
		return
	end

	-- Check if file is an accepted file type
	if not utils.is_accepted_file_type(file, files_types) then
		log.display_notify(3, "File has not an accepted type. \nAccepted types: " .. table.concat(files_types, ", "))
		return
	end

	-- Launch Data Explorer
	core.render(opts, file)
end

return M
