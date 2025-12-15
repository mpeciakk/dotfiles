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

      vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find git files" })
      vim.keymap.set("n", "<leader>fr", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Search buffers" })
      vim.keymap.set("n", "<leader>fh", ":Telescope find_files hidden=true <CR>", { desc = "Search hidden files" })
  
      vim.keymap.set('n', '<leader>pws', function()
          local word = vim.fn.expand("<cword>")
          builtin.grep_string({ search = word })
      end)
      vim.keymap.set('n', '<leader>pWs', function()
          local word = vim.fn.expand("<cWORD>")
          builtin.grep_string({ search = word })
      end)
      vim.keymap.set('n', '<leader>ps', function()
          builtin.grep_string({ search = vim.fn.input("Grep > ") })
      end)
  end
}
