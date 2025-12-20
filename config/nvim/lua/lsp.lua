vim.lsp.enable({
  "lua_ls",
  -- "c3_lsp",
  -- "clangd",
  -- "docker_language_server",
  -- "docker_compose_language_service",
  -- "kotlin_lsp",
  -- "kotlin_language_server",
  "tsgo",
  "hyprls",
  "biome",
  "css_ls",
})

vim.diagnostic.config({
  virtual_lines = false,
  -- virtual_text = true,
  underline = true,
  update_in_insert = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
})

local function lsp_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    print("󰅚 No LSP clients attached")
    return
  end

  print("󰒋 LSP Status for buffer " .. bufnr .. ":")
  print("─────────────────────────────────")

  for i, client in ipairs(clients) do
    print(string.format("󰌘 Client %d: %s (ID: %d)", i, client.name, client.id))
    print("  Root: " .. (client.config.root_dir or "N/A"))
    print("  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))

    -- Check capabilities
    local caps = client.server_capabilities
    local features = {}
    if caps.completionProvider then
      table.insert(features, "completion")
    end
    if caps.hoverProvider then
      table.insert(features, "hover")
    end
    if caps.definitionProvider then
      table.insert(features, "definition")
    end
    if caps.referencesProvider then
      table.insert(features, "references")
    end
    if caps.renameProvider then
      table.insert(features, "rename")
    end
    if caps.codeActionProvider then
      table.insert(features, "code_action")
    end
    if caps.documentFormattingProvider then
      table.insert(features, "formatting")
    end

    print("  Features: " .. table.concat(features, ", "))
    print("")
  end
end

vim.api.nvim_create_user_command("LspStatus", lsp_status, { desc = "Show detailed LSP status" })
