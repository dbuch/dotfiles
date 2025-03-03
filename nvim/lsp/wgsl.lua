vim.filetype.add {
  extension = {
    wgsl = 'wgsl',
  },
}

---@type vim.lsp.Config
return {
  cmd = { 'wgsl_analyzer' },
  filetypes = { 'wgsl' },
}
