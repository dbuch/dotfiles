---@type vim.lsp.Config
return {
  cmd = { 'vscode-css-languageserver', '--stdio' },
  filetypes = { 'css', 'scss', 'less' },
  root_dir = function(cb)
    cb(vim.fn.getcwd())
  end,

  init_options = {
    provideFormater = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },

  settings = {
    css = { validate = true },
    scss = { validate = true },
    less = { validate = true },
  },
}
