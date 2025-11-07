local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

local utils = require("data-explorer.core.utils")
local core = require("data-explorer.core.core")
local display = require("data-explorer.ui.display")
local log = require("data-explorer.gestion.log")

local M = {}

--- Create a previewer for Telescope.
---@return table: Telescope previewer.
local function picker_previewer()
	return previewers.new_buffer_previewer({
		define_preview = function(self, entry)
			local file = entry.value

			-- Fetch and cache metadata
			local cached, err = utils.get_cached_metadata(file)
			if not cached then
				log.display_notify(4, "Error fetching metadata: " .. err)
				return
			end

			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, display.prepare_metadata(file, cached))
		end,
	})
end

--- Telescope picker for Data Explorer
---@param opts table: user options
---@param extensions table: file extensions
function M.pickers_files(opts, extensions)
	local find_command = utils.build_fd_command(extensions, opts.telescope_opts.finder)

	pickers
		.new(opts, {
			prompt_title = "Data Explorer Files",
			layout_strategy = opts.telescope_opts.layout_strategy,
			layout_config = {
				height = opts.telescope_opts.layout_config.height,
				width = opts.telescope_opts.layout_config.width,
				preview_cutoff = opts.telescope_opts.layout_config.preview_cutoff,
				preview_width = (opts.telescope_opts.layout_strategy == "horizontal")
						and opts.telescope_opts.layout_config.preview_width
					or nil,
				preview_height = (opts.telescope_opts.layout_strategy == "vertical")
						and opts.telescope_opts.layout_config.preview_height
					or nil,
			},

			finder = finders.new_oneshot_job(find_command, {
				cwd = vim.fn.getcwd(),
			}),
			previewer = picker_previewer(),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				local function on_select()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if selection then
						core.render(opts, selection.value)
					else
						log.display_notify(3, "No file selected")
					end
				end
				map("i", "<CR>", on_select)
				map("n", "<CR>", on_select)
				return true
			end,
		})
		:find()
end

return M
