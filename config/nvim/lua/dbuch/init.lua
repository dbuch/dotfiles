local NvimTrait = require 'dbuch.traits.nvim'

safe_require 'dbuch.options'
safe_require 'dbuch.mappings'

NvimTrait.init_printf()

---@class DevSpec
---@field path string
---@field patterns string[]
---@field fallback boolean

require('lazy').setup {
  spec = {
    { import = 'dbuch.plugins' },
  },
  defaults = {
    lazy = true,
  },
  checker = {
    enabled = true,
    notify = true,
    frequency = 14400, -- Every fourth hour
  },
  change_detection = {
    notify = false,
  },
  ---@type DevSpec
  dev = {
    path = '~/dev/nvim/plugins/',
    patterns = {},
    fallback = false,
  },
  lockfile = vim.fn.stdpath 'data' .. '/lazy-lock.json',--[[@type string]]
  performance = {
    cache = {
      enabled = not vim.loader.enabled,
    },
    rtp = {
      disabled_plugins = {
        'compiler',
        'bugreport',
        '2html_plugin',
        'ftplugin',
        'optwin',
        'syntax',
        'netrw',
        'netrwPlugin',
        'matchit',
        'matchparen',
        'tutor',
        'tohtml',
        'vimball',
        'vimballPlugin',
        'tarPlugin',
        'zipPlugin',
        'gzip',
      },
    },
  },
  debug = vim.env.LAZY_DEBUG or false,
}

safe_require 'dbuch.autocmds'
safe_require 'dbuch.status'
safe_require 'dbuch.macros'

safe_require 'lsp'
