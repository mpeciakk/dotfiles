return {
  {
    "williamboman/mason.nvim",
    lazy = false, -- Load immediately to ensure PATH is set
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "typescript-language-server",
        "stylua",
        "luacheck",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
    end,
  },
}
