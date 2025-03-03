---@type vim.lsp.Config
return {
  cmd = { 'vscode-html-languageserver', '--stdio' },
  filetypes = { 'html', 'templ' },

  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },

  settings = {},
}
