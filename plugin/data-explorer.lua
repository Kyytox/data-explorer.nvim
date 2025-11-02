local M = require("data-explorer")

-- Launch Data Explorer
vim.api.nvim_create_user_command("DataExplorer", function()
	M.data_explorer()
end, { desc = "Open Data Explorer" })

-- Launch Data Explorer for current files
vim.api.nvim_create_user_command("DataExplorerFile", function()
	M.data_explorer_file()
end, { desc = "Open Data Explorer for current file" })
