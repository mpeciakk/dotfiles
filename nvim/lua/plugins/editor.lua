return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<C-e>",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      }
    },
  },
}