-- Modules
local config = require("data-explorer.config")
local utils = require("data-explorer.utils")
local picker = require("data-explorer.ui.picker")
local core = require("data-explorer.core")
local check_focus = require("data-explorer.check_focus")

local M = {}

--- @param opts table|nil: User configuration options.
function M.setup(opts)
	config.setup(opts)

	-- Launch Data Explorer
	vim.api.nvim_create_user_command("DataExplorer", function()
		M.data_explorer()
	end, {
		desc = "Open Data Explorer",
		nargs = 0,
	})

	-- Launch Data Explorer for current files
	vim.api.nvim_create_user_command("DataExplorerFile", function()
		M.data_explorer_file()
	end, {
		desc = "Open Data Explorer for current file",
		nargs = 0,
	})
end

-- Set Autocommands
local function set_autocommands()
	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		callback = check_focus.check_focus_and_close,
		group = vim.api.nvim_create_augroup("DataExplorerGroup", { clear = true }),
	})
end

--- Main function Data Explorer
function M.data_explorer()
	local opts = config.get()

	-- Set Autocommands
	set_autocommands()

	-- -- Find all .parquet file
	local parquet_files = utils.get_files_in_working_directory()

	if #parquet_files == 0 then
		vim.notify("No .parquet files found in current directory", vim.log.levels.WARN)
		return
	end

	-- Launch Data Explorer
	picker.pickers_files(opts, parquet_files)
end

--- Data Explorer File
function M.data_explorer_file()
	local opts = config.get()

	-- Set Autocommands
	set_autocommands()

	-- Get current buffer file
	local file = vim.api.nvim_buf_get_name(0)

	if file == nil or file == "" then
		vim.notify("No file found in current buffer", vim.log.levels.WARN)
		return
	end

	-- Check if file is a .parquet file
	if not file:match("%.parquet$") then
		vim.notify("Current file is not a .parquet file", vim.log.levels.WARN)
		return
	end

	-- Launch Data Explorer
	core.render(opts, file)
end

return M
