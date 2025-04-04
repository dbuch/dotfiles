---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    cmd = 'LazyDev',
    dependencies = {
      { 'Bilal2453/luvit-meta' },
    },
    ---@module 'lazydev'
    ---@type lazydev.Config
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
      integrations = {
        lspconfig = false,
        cmp = false,
        coq = false,
      },
    },
  },
}
