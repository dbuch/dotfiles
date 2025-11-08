---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'folke/trouble.nvim',
    ---@module 'trouble'
    ---@type trouble.Config
    opts = {
      use_diagnostic_signs = true,
    },
    cmd = { 'TroubleToggle', 'Trouble' },
  },
}
