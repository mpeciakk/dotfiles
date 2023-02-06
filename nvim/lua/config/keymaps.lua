vim.g.mapleader = " "

local map = vim.keymap.set

map("n", "nh", ":nohl<CR>")

map("n", "x", '"_x')

-- splitting windows
map("n", "sv", "<C-w>v")
map("n", "sh", "<C-w>s")
map("n", "se", "<C-w>=")
map("n", "sx", ":close<CR>")

-- tabs
map("n", "to", ":tabnew<CR>")
map("n", "tx", ":tabclose<CR>")
map("n", "tn", ":tabn<CR>")
map("n", "tp", ":tabp<CR>")

map("n", "<C-up>", "<C-w><up>")
map("n", "<C-down>", "<C-w><down>")
map("n", "<C-left>", "<C-w><left>")
map("n", "<C-right>", "<C-w><right>")
map("n", "<C-Space>", "")

map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- nvim-tree
map("n", "<C-e>", ":NvimTreeToggle<CR>")

-- telescope
map("n", "ff", "<cmd>Telescope find_files<cr>")
