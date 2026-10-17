---@module 'lazy'
---@type LazyPluginSpec[]
return {
  -- {
  --   'lewis6991/github_dark.nvim',
  --   dev = true,
  --   lazy = false,
  --   priority = 1000,
  --   config = function(_, _)
  --     vim.cmd.color('github_dark')
  --   end,
  -- },
  {
    'mcauley-penney/techbase.nvim',
    lazy = false,
    dev = true,
    priority = 1000,
    opts = {
      italic_comments = true,

      -- set to true to make the background, floating windows, statusline,
      -- signcolumn, foldcolumn, and tabline transparent
      transparent = false,

      -- Here, you can disable plugins. All plugins that techbase supports
      -- are enabled by default. You do not need to specify the ones you
      -- want to enable, only those you wish to disable. This table
      -- accepts key-pair values.
      plugin_support = {
        aerial = false,
        edgy = false,
        mason = false,
        nvim_cmp = false,
        vim_highlighturl = false,
      },

      -- You can enable *only* some plugins by using the "only" table
      -- inside of the "plugin_support" table. This table accepts strings.
      -- plugin_support = {
      --   only = { "visual_whitespace" }
      -- },

      -- allows you to override any highlight group for finer-grained control
      hl_overrides = {},
    },
    config = function(_, opts)
      require('techbase').setup(opts)
      vim.cmd.colorscheme('techbase')
    end,
  },
}
