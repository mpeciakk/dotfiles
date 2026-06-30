return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto", -- picks up tokyonight
      globalstatus = true,
      section_separators = "",
      component_separators = "|",
    },
  },
}
