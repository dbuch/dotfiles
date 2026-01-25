---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy', -- Or `LspAttach`
    priority = 1000, -- needs to be loaded in first
    opts = {
      preset = 'simple',
      options = {
        show_source = true,
        use_icons_from_diagnostic = true,
        multiple_diag_under_cursor = true,
        overflow = {
          mode = 'wrap',
          padding = 0,
        },
        multilines = {
          enabled = true,
        },
        break_line = {
          enabled = true,
          after = 60,
        },
      },
    },
  },
}
