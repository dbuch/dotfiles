---@type vim.lsp.Config
return {
  cmd = { 'vscode-json-languageserver', '--stdio' },
  filetypes = { 'json' },
  settings = {},
  init_options = {
    provideFormatter = true,
  },
}
