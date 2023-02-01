return {
  -- filetree
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<C-e>",
        function()
          require("neo-tree.command").execute({ toggle = false, dir = vim.loop.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      }
    },
  },

  -- auto pairs
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    config = function(_, opts)
      require("mini.pairs").setup(opts)
    end,
  },
  
  -- indent helper
  { "lukas-reineke/indent-blankline.nvim" },
}
