function _G.get_oil_winbar()
	local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local dir = require("oil").get_current_dir(bufnr)
	if dir then
		return vim.fn.fnamemodify(dir, ":~")
	else
		-- If there is no current directory (e.g. over ssh), just show the buffer name
		return vim.api.nvim_buf_get_name(0)
	end
end

return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {},
	-- share a single icon provider with bufferline
	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
	config = function()
		require("oil").setup({
			default_file_explorer = true,
			skip_confirm_for_simple_edits = true,
			win_options = {
				winbar = "%!v:lua.get_oil_winbar()",
			},
			view_options = {
				show_hidden = true,
			},
		})
	end,
}
