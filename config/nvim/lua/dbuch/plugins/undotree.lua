---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'jiaoshijie/undotree',
    opts = {
      float_diff = true,
      window = {
        winblend = 5,
      },
    },
    keys = {
      { '<leader>u', "<cmd>lua require('undotree').toggle()<cr>" },
    },
  },
}
