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
  {
    'mrcjkb/rustaceanvim',
    version = false, -- Recommended
    lazy = false, -- This plugin is already lazy
    ---@module 'rustaceanvim'
    ---@type rustaceanvim.Opts
    opts = {
      server = {
        default_settings = {
          ['rust-analyzer'] = {
            cargo = {
              extraEnv = {
                RUSTUP_TOOLCHAIN = 'stable',
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend('keep', vim.g.rustaceanvim or {}, opts or {})
    end,
  },
}
