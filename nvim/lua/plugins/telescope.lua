local status, telescope = pcall(require, "telescope")
if not status then
  return
end

local actions_setup, actions = pcall(require, "telescope.actions")
if not status then
  return
end

telescope.setup({
  defaults = {
    mappings = {
      i = {

      }
    }
  }
})

telescope.load_extension("fzf")
