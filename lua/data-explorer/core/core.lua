-- Modules
local state = require("data-explorer.gestion.state")
local utils = require("data-explorer.core.utils")
local windows = require("data-explorer.ui.windows")
local display = require("data-explorer.ui.display")
local config_windows = require("data-explorer.ui.config_windows")
local duckdb = require("data-explorer.core.duckdb")
local log = require("data-explorer.gestion.log")
local mappings = require("data-explorer.ui.mappings")

local M = {}

--- Create Buffer with lines
---@param lines table|nil: Lines to set in the buffer.
---@return number: Buffer number.
local function create_buffer_with_lines(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	if lines then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end
	return buf
end

-- Create buffers
local function create_buffers(opts, file, metadata, data)
	-- Metadata
	local metadata_lines = display.prepare_metadata(file, metadata)
	local buf_meta = create_buffer_with_lines(metadata_lines)
	state.set_state("buffers", "buf_meta", buf_meta)

	-- Main data
	local buf_data = create_buffer_with_lines(data)
	state.set_state("buffers", "buf_data", buf_data)
	if opts.hl.buffer.hl_enable then
		display.update_highlights(buf_data, data)
	end

	-- SQL buffer
	local sql_lines = display.prepare_sql_display(opts)
	local buf_sql = create_buffer_with_lines(sql_lines)
	state.set_state("buffers", "buf_sql", buf_sql)

	-- SQL error
	local buf_sql_err = create_buffer_with_lines({ "" })
	state.set_state("buffers", "buf_sql_err", buf_sql_err)

	return #metadata_lines, #data
end

--- Main Function
---@param opts table: Options table.
---@param file string: Path to the file.
function M.render(opts, file)
	-- local start = os.clock()
	local err
	local data = nil
	local metadata = nil
	local top_store_duckdb = opts.use_storage_duckdb

	-- Fetch metadata
	metadata, err = utils.get_cached_metadata(file)
	if not metadata then
		log.display_notify(4, "Error fetching metadata: " .. err)
		return
	end

	if metadata.count_lines == 0 then
		log.display_notify(3, "The file is empty: " .. file)
		return
	end

	-- Fetch main data
	data, err = duckdb.fetch_main_data(file, metadata.file_ext, top_store_duckdb, opts.limit)
	if not data then
		log.display_notify(4, "Error fetching data: " .. err)
		return
	end

	-- Store current file in state
	state.set_state("current_file", nil, file)
	state.set_state("current_layout", nil, opts.layout)
	state.set_state("num_page", nil, 1)
	state.set_state("max_num_page", nil, math.ceil(metadata.count_lines / opts.limit))

	-- Create buffers
	local nb_meta_lines, nb_data_lines = create_buffers(opts, file, metadata, data)

	-- Calculate window layout
	local tbl_dimensions =
		config_windows.calculate_window_layout(opts, vim.o.columns, vim.o.lines, nb_meta_lines, nb_data_lines)

	-- get windows layout info according to the layout
	tbl_dimensions = tbl_dimensions[opts.layout]

	-- Create Metadata and Data windows
	windows.create_windows(opts, tbl_dimensions)

	-- Set keymaps for buffers
	mappings.set_common_keymaps(opts)
	-- log.info(string.format("Main Data for %s in %.4f seconds.", file, os.clock() - start))
end

return M
