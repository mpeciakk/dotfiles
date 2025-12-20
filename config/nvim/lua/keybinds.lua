local map = vim.keymap.set

map("n", "<leader>ee", "<CMD>Oil<CR>", { desc = "Open Oil in buffer dir" })
map("n", "<leader>ef", "<CMD>Oil .<CR>", { desc = "Open Oil in cwd" })

map("n", "<leader>l", function()
  require("conform").format({ bufnr = 0 })
end)

map("n", "gD", vim.lsp.buf.declaration)
map("n", "gd", vim.lsp.buf.definition)
map("n", "K", vim.lsp.buf.hover)
map("n", "qf", vim.lsp.buf.code_action)
