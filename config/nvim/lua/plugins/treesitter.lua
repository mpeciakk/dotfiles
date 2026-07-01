return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- the main branch does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "c",
        "cpp",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "dockerfile",
        "yaml",
        "bash",
        "regex",
      })

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          -- only enable features for filetypes with an installed parser
          if not lang or not pcall(vim.treesitter.start, args.buf) then
            return
          end
          -- indentation, provided by nvim-treesitter (folds are handled by nvim-ufo)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
