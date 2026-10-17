---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'seblyng/roslyn.nvim',
    ft = 'cs',
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      extensions = {
        razor = {
          enabled = true,
          config = function()
            return { path = nil }
          end,
        },
      },
    },
  },
}
