return {
  "nvim-telescope/telescope.nvim",
  tag = '0.1.8',

  dependencies = {
      "nvim-lua/plenary.nvim"
  },

  config = function()
      require('telescope').setup({
        defaults = {
          preview = {
            treesitter = false,
          }
        }
      })

      local builtin = require('telescope.builtin')

      -- find: files
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Files" })
      vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Git files" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", ":Telescope find_files hidden=true<CR>", { desc = "Hidden files" })

      -- search: content & symbols
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Diagnostics" })
      vim.keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "Document symbols" })
      vim.keymap.set("n", "<leader>sS", builtin.lsp_dynamic_workspace_symbols, { desc = "Workspace symbols" })
      vim.keymap.set("n", "<leader>sw", function()
        builtin.grep_string({ search = vim.fn.expand("<cword>") })
      end, { desc = "Grep word under cursor" })
      vim.keymap.set("n", "<leader>sW", function()
        builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
      end, { desc = "Grep WORD under cursor" })
      vim.keymap.set("n", "<leader>s/", function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") })
      end, { desc = "Grep by input" })

      -- LSP references (telescope picker)
      vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "LSP references" })
  end
}
