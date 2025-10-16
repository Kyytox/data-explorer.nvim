-- Modules
local state = require("data-explorer.state")
local utils = require("data-explorer.utils")
local windows = require("data-explorer.ui.windows")
local display = require("data-explorer.ui.display")
local config_windows = require("data-explorer.ui.config_windows")
local duckdb = require("data-explorer.duckdb")
local mappings = require("data-explorer.ui.mappings")

local M = {}

-- Create buffers
local function create_buffers(opts, file, metadata, data)
	-- Prepare display help
	local help_lines = display.prepare_help(opts)
	local buf_help = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf_help, 0, -1, false, help_lines)
	state.set_state("buffers", "buf_help", buf_help)

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
	vim.api.nvim_buf_set_lines(buf_sql, 0, -1, false, { "lect month from f;" })
	state.set_state("buffers", "buf_sql", buf_sql)

	return #metadata_lines, #data_lines
end

--- Main Function
---@param opts table: Options table.
---@param file string: Path to the parquet file.
function M.render(opts, file)
	local layout = opts.layout

	-- Fetch and parse data
	local data, err = duckdb.fetch_parse_data(file, "data")
	if not data then
		vim.notify("Error fetching data: " .. (err or "unknown"), vim.log.levels.ERROR)
		return
	end

	-- Fetch and cache metadata
	local metadata = utils.get_cached_metadata(file)
	if not metadata then
		return
	end

	-- Store current file in state
	state.set_state("current_file", nil, file)

	-- Create buffers
	local nb_meta_lines, nb_data_lines = create_buffers(opts, file, metadata, data)
	-- vim.notify(vim.inspect(state.get_state("buffers")), vim.log.levels.INFO)

	-- Calculate window layout
	local wins_layout = config_windows.calculate_window_layout(nb_meta_lines, nb_data_lines)

	-- get windows layout info according to the layout
	if layout == "vertical" then
		wins_layout = wins_layout.vertical
	elseif layout == "horizontal" then
		wins_layout = wins_layout.horizontal
	end

	-- Create Metadata and Data windows
	windows.create_windows(opts, wins_layout)

	-- Set keymaps for buffers
	mappings.set_common_keymaps(opts)
end

return M
