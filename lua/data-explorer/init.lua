local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local Path = require("plenary.path")
local M = {}

-- Modules
local log = require("data-explorer.log")
local config = require("data-explorer.config")
local duckdb = require("data-explorer.duckdb")
local utils = require("data-explorer.utils")
local windows = require("data-explorer.ui.windows")
local display = require("data-explorer.ui.display")

--- Fetch and parse data for a parquet file.
---@param file string: File path.
---@param type string: "data" or "metadata".
---@return table|nil, string|nil: Metadata or error message.
local function fetch_parse_data(file, type)
	local csv_text = nil
	local err = nil

	-- Fetch Data
	if type == "data" then
		csv_text, err = duckdb.get_data_csv(file)
	else
		csv_text, err = duckdb.get_metadata_csv(file)
	end

	if not csv_text then
		vim.notify("DuckDB error: " .. (err or "unknown"), vim.log.levels.ERROR)
		return
	end

	-- Parse CSV data
	local data_headers, data_content = duckdb.parse_csv(csv_text)
	if not data_headers then
		vim.notify("Failed to parse CSV: " .. data_content, vim.log.levels.WARN)
		return
	end

	return { headers = data_headers, data = data_content }, nil
end

--- Get metadata and cache it
---@param file string: File path.
---@return table|nil, string|nil: Metadata or error message.
local function get_cached_metadata(file)
	-- Check cache first
	if M.file_metadata_cache[file] then
		return M.file_metadata_cache[file]
	end

	-- Fetch and parse metadata
	local metadata = fetch_parse_data(file, "metadata")
	if not metadata then
		return nil
	end

	-- Cache metadata
	M.file_metadata_cache[file] = metadata

	return metadata
end

--- Preview a parquet file.
---@param file string: File path.
function M.preview_parquet(file)
	local opts = config.get()

	-- Fetch and parse data
	local data_result, err = fetch_parse_data(file, "data")
	if not data_result then
		vim.notify("Error fetching data: " .. (err or "unknown"), vim.log.levels.ERROR)
		return
	end

	-- Fetch and cache metadata
	local metadata_result = get_cached_metadata(file)
	if not metadata_result then
		return
	end

	-- render_display(opts, file, data_headers, data_content, metadata_result.headers, metadata_result.data)
	display.render(M, opts, file, data_result.headers, data_result.data, metadata_result.headers, metadata_result.data)
end

--- Create a previewer for Telescope.
---@return table: Telescope previewer.
local function telescope_previewer()
	return previewers.new_buffer_previewer({
		define_preview = function(self, entry)
			local file = entry.value

			-- Fetch and cache metadata
			local cached = get_cached_metadata(file)
			if not cached then
				return
			end

			vim.api.nvim_buf_set_lines(
				self.state.bufnr,
				0,
				-1,
				false,
				utils.prepare_metadata_display(file, cached.headers, cached.data)
			)
		end,
	})
end

--- @param opts table|nil: User configuration options.
function M.setup(opts)
	config.setup(opts)
	-- vim.notify = require("notify")
	-- vim.api.nvim_create_user_command("DataExplorer", function()
	-- 	M.select_parquet_file({
	-- 		layout = config.get().layout,
	-- 		limit = config.get().limit,
	-- 	})
	-- end, {
	-- 	-- Command Options:
	-- 	desc = "Open Data Explorer",
	-- 	nargs = 0,
	-- })

	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		callback = display.check_focus_and_close,
		group = vim.api.nvim_create_augroup("TestPluginGroup", { clear = true }),
	})
end

--- Select a parquet file using Telescope.
---@param opts table: Options (layout).
function M.select_parquet_file(opts)
	opts = config.get()

	local work_dir = vim.fn.getcwd()

	-- Find all .parquet files
	local parquet_files = vim.tbl_map(function(f)
		return Path:new(f):absolute()
	end, vim.fn.glob(work_dir .. "/**/*.parquet", true, true))

	if #parquet_files == 0 then
		vim.notify("No .parquet files found in current directory", vim.log.levels.WARN)
		return
	end

	M.file_metadata_cache = M.file_metadata_cache or {}

	pickers
		.new(opts, {
			prompt_title = "Select Parquet File",
			layout_strategy = opts.layout,
			layout_config = {
				height = 0.5,
				width = 0.9,
				preview_cutoff = 1,
				preview_height = (opts.layout == "vertical") and 0.4 or nil,
				preview_width = (opts.layout == "horizontal") and 0.4 or nil,
			},
			finder = finders.new_table({ results = parquet_files }),
			previewer = telescope_previewer(),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				local function on_select()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if selection then
						M.preview_parquet(selection[1])
					else
						vim.notify("No file selected", vim.log.levels.WARN)
					end
				end
				map("i", "<CR>", on_select)
				map("n", "<CR>", on_select)
				return true
			end,
		})
		:find()
end

-- M.select_parquet_file({ layout = "Vertical", limit = 100 })

return M
