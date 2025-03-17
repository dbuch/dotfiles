---@type vim.lsp.Config
return {
  cmd = { 'tinymist' },
  filetypes = { 'typst' },
  root_dir = function(bufnr, cb)
    local root = vim.fs.root(0, '.git')
    cb(root)
  end,
}
