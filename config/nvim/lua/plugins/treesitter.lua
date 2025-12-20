return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "main",
    lazy = vim.fn.argc(-1) == 0,
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts_extend = { "ensure_installed" },
    opts = {
      indent = { enable = true },
      highlight = { enable = true },
      folds = { enable = true },
      ensure_installed = {
        "c",
        "cpp",
        "lua",
        "vim",
        "markdown_inline",
        "markdown",
        "dockerfile",
        "yaml",
        "bash",
        "regex",
      },
    },
    config = function(_, opts)
      local TS = require("nvim-treesitter")

      TS.setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          if vim.tbl_get(opts, "highlight", "enable") ~= false then
            pcall(vim.treesitter.start)
          end
        end,
      })
    end,
  },
}
