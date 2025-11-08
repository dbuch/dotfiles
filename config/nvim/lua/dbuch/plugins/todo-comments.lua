---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'folke/todo-comments.nvim',
    event = 'BufReadPre',
    opts = {},
  },
}
