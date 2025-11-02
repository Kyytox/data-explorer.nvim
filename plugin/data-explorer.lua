-- require("data-explorer")

if 1 ~= vim.fn.has("nvim-0.10.0") then
	vim.api.nvim_err_writeln("data-explorer.nvim requires Neovim 0.10.0 or higher")
	return
end

if vim.g.loaded_data_explorer == 1 then
	return
end
vim.g.loaded_data_explorer = 1

local data_explorer = require("data-explorer")
data_explorer.setup()
