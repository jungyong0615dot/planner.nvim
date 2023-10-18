local M = {}

M.create_augroup = function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "python",
		command = "set tabstop=2 softtabstop=2 shiftwidth=2 smartindent expandtab foldmethod=expr foldexpr=BlockFolds() foldlevel=1",
	})
end

return M
