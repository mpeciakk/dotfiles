local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

map("n", "<C-up>", "<C-w><up>")
map("n", "<C-down>", "<C-w><down>")
map("n", "<C-left>", "<C-w><left>")
map("n", "<C-right>", "<C-w><right>")
map("n", "<C-e>", "<Neotree>")

map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
