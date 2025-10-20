-- Modules
local state = require("data-explorer.gestion.state")
local utils = require("data-explorer.core.utils")
local windows = require("data-explorer.ui.windows")
local display = require("data-explorer.ui.display")
local config_windows = require("data-explorer.ui.config_windows")
local duckdb = require("data-explorer.core.duckdb")
local mappings = require("data-explorer.ui.mappings")

local M = {}

-- Create buffers
local function create_buffers(opts, file, metadata, data)
	-- Prepare display help if not disabled
	if opts.window_opts.hide_window_help == false then
		local help_lines = display.prepare_help(opts)
		local buf_help = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf_help, 0, -1, false, help_lines)
		state.set_state("buffers", "buf_help", buf_help)
	end

	-- Prepare display metadata
	local metadata_lines = display.prepare_metadata(file, metadata)
	local buf_meta = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf_meta, 0, -1, false, metadata_lines)
	state.set_state("buffers", "buf_meta", buf_meta)

	-- Prepare display data
	local data_lines = display.prepare_data(data.headers, data.data)
	local buf_data = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf_data, 0, -1, false, data_lines)
	state.set_state("buffers", "buf_data", buf_data)

	-- Prepare display sql
	local sql_help = display.prepare_sql_help(opts)
	local buf_sql_help = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf_sql_help, 0, -1, false, sql_help)
	state.set_state("buffers", "buf_sql_help", buf_sql_help)

	-- Create SQL error buffer
	local buf_sql_err = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf_sql_err, 0, -1, false, { "" })
	state.set_state("buffers", "buf_sql_err", buf_sql_err)

	-- Create SQL buffer
	local buf_sql = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf_sql, 0, -1, false, { "select nom, age from f;" })
	state.set_state("buffers", "buf_sql", buf_sql)

	return #metadata_lines, #data_lines
end

--- Main Function
---@param opts table: Options table.
---@param file string: Path to the parquet file.
function M.render(opts, file)
	-- Fetch and parse data
	local data = duckdb.fetch_parse_data(file, "data")
	if not data then
		return
	end

	-- Fetch and cache metadata
	local metadata = utils.get_cached_metadata(file)
	if not metadata then
		return
	end

	-- Store current file in state
	state.set_state("current_file", nil, file)
	state.set_state("current_layout", nil, opts.layout)
	local width, height = vim.o.columns, vim.o.lines

	-- Create buffers
	local nb_meta_lines, nb_data_lines = create_buffers(opts, file, metadata, data)

	-- Calculate window layout
	local tbl_dimensions = config_windows.calculate_window_layout(opts, width, height, nb_meta_lines, nb_data_lines)

	-- get windows layout info according to the layout
	tbl_dimensions = tbl_dimensions[opts.layout]

	-- Create Metadata and Data windows
	windows.create_windows(opts, tbl_dimensions)

	-- Set keymaps for buffers
	mappings.set_common_keymaps(opts)
end

return M
