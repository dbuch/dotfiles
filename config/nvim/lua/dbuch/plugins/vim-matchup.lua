---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'andymass/vim-matchup',
    event = 'BufReadPre',
    ---@module 'match-up'
    ---@type matchup.Config
    ---@diagnostic disable: missing-fields
    opts = {
      enabled = 1,
      treesitter = {
        enable = 1,
        include_match_words = true,
        stopline = 500,
      },
      matchparen = {
        deferred = 1,
        deferred_show_delay = 100,
        offscreen = {
          method = 'status_manual',
        },
      },
    },
  },
}
