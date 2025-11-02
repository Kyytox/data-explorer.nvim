-- require("data-explorer")

if 1 ~= vim.fn.has("nvim-0.10.0") then
	vim.api.nvim_err_writeln("data-explorer.nvim requires Neovim 0.10.0 or higher")
	return
end

if vim.g.loaded_data_explorer == 1 then
	return
end
vim.g.loaded_data_explorer = 1

local M = require("data-explorer")
M.setup()

-- Launch Data Explorer
vim.api.nvim_create_user_command("DataExplorer", function()
	M.data_explorer()
end, { desc = "Open Data Explorer", nargs = 0 })

-- Launch Data Explorer for current files
vim.api.nvim_create_user_command("DataExplorerFile", function()
	M.data_explorer_file()
end, { desc = "Open Data Explorer for current file", nargs = 0 })
