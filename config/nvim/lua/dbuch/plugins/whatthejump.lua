---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'lewis6991/whatthejump.nvim',
    dev = true,
    keys = {
      { '<M-k>', 'Jump backwards' },
      { '<M-j>', 'Jump forwards' },
      { '<C-o>', 'Jump backwards' },
      { '<C-o>', 'Jump forwards' },
    },
    config = function()
      -- Jump backwards
      vim.keymap.set('n', '<M-k>', function()
        require('whatthejump').show_jumps(false)
        return '<C-o>'
      end, { expr = true })

      -- Jump forwards
      vim.keymap.set('n', '<M-j>', function()
        require('whatthejump').show_jumps(true)
        return '<C-i>'
      end, { expr = true })
    end,
  },
}
