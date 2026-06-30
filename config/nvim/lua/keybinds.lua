local map = vim.keymap.set

-- explorer
map("n", "<leader>ee", "<CMD>Oil<CR>", { desc = "Oil (buffer dir)" })
map("n", "<leader>ef", "<CMD>Oil .<CR>", { desc = "Oil (cwd)" })

-- LSP navigation (standard g-prefix)
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover docs" })

-- code: actions on the current buffer
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>cf", function()
  require("conform").format({ bufnr = 0 })
end, { desc = "Format buffer" })

-- toggles
map("n", "<leader>th", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })
