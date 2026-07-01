return {
  "saghen/blink.cmp",
  version = "1.*", -- pulls a prebuilt fuzzy-matcher binary, no Rust toolchain needed
  dependencies = { "rafamadriz/friendly-snippets" },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "default" }, -- <C-y> to accept, <C-space> for menu/docs
    appearance = { nerd_font_variant = "mono" },
    completion = { documentation = { auto_show = true } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
