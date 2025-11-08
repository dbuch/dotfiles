---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'rachartier/tiny-code-action.nvim',
    event = 'LspAttach',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      {
        'folke/snacks.nvim',
        opts = {
          terminal = {},
        },
      },
    },
    opts = {
      backend = 'vim',
      picker = {
        'buffer',
        opts = {
          hotkeys = true,
          hotkeys_mode = function(titles, _used_hotkeys)
            local t = {}
            for i = 1, #titles do
              t[i] = tostring(i)
            end
            return t
          end,
          auto_accept = true,
          auto_preview = false,
          position = 'cursor',
          winborder = 'single',
        },
      },
    },
  },
}
