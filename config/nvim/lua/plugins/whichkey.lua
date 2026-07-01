return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    -- group labels so the popup is organized when you press <leader>
    spec = {
      { "<leader>a", group = "AI/Claude" },
      { "<leader>c", group = "code" },
      { "<leader>e", group = "explorer" },
      { "<leader>f", group = "find files" },
      { "<leader>h", group = "git hunk" },
      { "<leader>s", group = "search" },
      { "<leader>t", group = "toggle" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
    {
      "<leader>sk",
      "<cmd>Telescope keymaps<cr>",
      desc = "Search keymaps",
    },
  },
}
