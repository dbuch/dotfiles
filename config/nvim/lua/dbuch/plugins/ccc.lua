---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'uga-rosa/ccc.nvim',
    cmd = 'CccPick',
    opts = function()
      local ccc = require('ccc')

      -- Use uppercase for hex codes.
      ccc.output.hex.setup({ uppercase = true })
      ccc.output.hex_short.setup({ uppercase = true })

      return {
        highlighter = {
          auto_enable = true,
          -- LSP causes the highlights to not cover the correct range.
          lsp = false,
        },
      }
    end,
  },
}
