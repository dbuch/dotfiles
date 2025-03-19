---@type vim.lsp.Config
return {
  cmd = { 'tinymist' },
  filetypes = { 'typ', 'typst' },
  root_dir = function(_bufnr, cb)
    local root = vim.fs.root(0, '.git')
    cb(root)
  end,
}
