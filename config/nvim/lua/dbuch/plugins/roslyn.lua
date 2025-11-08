---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'seblyng/roslyn.nvim',
    lazy = false,
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      -- your configuration comes here; leave empty for default settings
    },
  },
}
