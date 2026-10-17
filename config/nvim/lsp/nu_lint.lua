---@type vim.lsp.Config
return {
  cmd = { 'nu-lint', '--lsp' },
  filetypes = { 'nu' },
  root_dir = function(_bufnr, cb)
    local root_path = vim.fs.root(0, '.git')
    cb(root_path or vim.fn.getcwd())
  end,
}
