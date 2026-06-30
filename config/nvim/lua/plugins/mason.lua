return {
  {
    "williamboman/mason.nvim",
    lazy = false, -- Load immediately to ensure PATH is set
    build = ":MasonUpdate",
    opts = {},
    config = function(_, opts)
      require("mason").setup(opts)
    end,
  },
}
