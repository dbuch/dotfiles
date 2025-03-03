---@type vim.lsp.Config
return {
  cmd = { 'nu', '--lsp' },
  filetypes = { 'nu' },
  root_dir = function(cb)
    local root_path = vim.fs.root(0, '.git')
    cb(root_path or vim.fn.getcwd())
  end,
}
