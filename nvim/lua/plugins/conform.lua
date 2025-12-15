return {
  "stevearc/conform.nvim",
  opts = {},
  config = function()
    require("conform").setup({
      format_on_save = {
        timeout_ms = 5000,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        kotlin = { "ktlint" },
        c = { "clang-format" },
        json = { "biome" },
        jsonc = { "biome" },
        javascript = { "biome" },
        typescript = { "biome" },
        css = { "biome" },
      },
    })
  end,
}
