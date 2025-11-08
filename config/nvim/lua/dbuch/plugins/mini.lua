---@type LazyPluginSpec[]
return {
  {
    'nvim-mini/mini.icons',
    version = '*',
    lazy = true,
    opts = {
      file = {
        ['.keep'] = { glyph = '󰊢', hl = 'MiniIconsGrey' },
        ['devcontainer.json'] = { glyph = '', hl = 'MiniIconsAzure' },
      },
      filetype = {
        dotenv = { glyph = '', hl = 'MiniIconsYellow' },
      },
    },
  },
  {
    'nvim-mini/mini.cursorword',
    event = 'BufReadPost',
    version = '*',
    opts = {},
  },
  {
    'nvim-mini/mini.pick',
    lazy = false,
    version = '*',
    opts = {
      mappings = {
        move_up = '<A-k>',
        move_down = '<A-j>',
      },
      options = {
        use_cache = true,
      },
    },
    config = function(_plugin, opts)
      -- Centered on screen
      local win_config = function()
        local height = math.floor(0.618 * vim.o.lines)
        local width = math.floor(0.618 * vim.o.columns)
        return {
          anchor = 'NW',
          height = height,
          width = width,
          row = math.floor(0.5 * (vim.o.lines - height)),
          col = math.floor(0.5 * (vim.o.columns - width)),
        }
      end

      opts.window = vim.tbl_extend('force', opts.window or {}, { config = win_config })

      require('mini.pick').setup(opts)

      vim.api.nvim_set_hl(0, 'MiniPickMatchCurrent', {
        link = 'Visual',
        --link = 'PmenuExtra',
      })
    end,
  },
  {
    'nvim-mini/mini.colors',
    init = function()
      vim.api.nvim_create_user_command('LoadMiniColors', function()
        vim.cmd('Lazy load mini.colors')
      end, {})
    end,
    cmd = 'LoadMiniColors',
    version = '*',
    config = function()
      require('mini.colors').setup()
    end,
  },
  {
    'nvim-mini/mini.files',
    lazy = false,
    version = '*',
    opts = {
      content = {
        filter = function(fs_entry)
          return not vim.startswith(fs_entry.name, '.')
        end,
      },
      windows = {
        max_number = 3,
        preview = false,
      },
    },
    config = function(_, opts)
      local minifiles = require('mini.files')

      minifiles.setup(opts)

      local miniext = require('dbuch.minifiles_ext').new()
      miniext:subscribe_events()
    end,
  },
  {
    'nvim-mini/mini.ai',
    version = '*',
    event = 'BufReadPre',
    config = true,
  },
  {
    'nvim-mini/mini.pairs',
    version = '*',
    event = 'InsertEnter',
    opts = {
      modes = { insert = true, command = true, terminal = false },
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      skip_ts = { 'string' },
      skip_unbalanced = true,
      markdown = true,
    },
  },
  {
    'nvim-mini/mini.comment',
    version = '*',
    --event = 'VeryLazy',
    keys = {
      {
        'gc',
        'gcc',
      },
    },
    dependencies = {
      {
        'JoosepAlviste/nvim-ts-context-commentstring',
        opts = {
          enable = true,
          enable_autocmd = false,
        },
      },
    },
    opts = {
      options = {
        custom_commentstring = function()
          return require('ts_context_commentstring.internal').calculate_commentstring()
            or vim.bo.commentstring
        end,
      },
    },
  },
  {
    'nvim-mini/mini.align',
    version = '*',
    opts = {},
    keys = {
      { 'ga', mode = { 'n', 'v' } },
      { 'gA', mode = { 'n', 'v' } },
    },
  },
  {
    'nvim-mini/mini.surround',
    version = '*',
    keys = function(_, keys)
      local plugin = require('lazy.core.config').spec.plugins['mini.surround']
      local opts = require('lazy.core.plugin').values(plugin, 'opts', false)
      local mappings = {
        { opts.mappings.add, desc = 'Add surrounding', mode = { 'n', 'v' } },
        { opts.mappings.delete, desc = 'Delete surrounding' },
        { opts.mappings.find, desc = 'Find right surrounding' },
        { opts.mappings.find_left, desc = 'Find left surrounding' },
        { opts.mappings.highlight, desc = 'Highlight surrounding' },
        { opts.mappings.replace, desc = 'Replace surrounding' },
        { opts.mappings.update_n_lines, desc = 'Update `MiniSurround.config.n_lines`' },
      }
      return vim.list_extend(
        vim
          .iter(mappings)
          :filter(function(m)
            return m[1] and #m[1] > 0
          end)
          :totable(),
        keys
      )
    end,
    opts = {
      mappings = {
        add = 'sa', -- Add surrounding in Normal and Visual modes
        delete = 'sd', -- Delete surrounding
        find = 'sf', -- Find surrounding (to the right)
        find_left = 'sF', -- Find surrounding (to the left)
        highlight = 'sh', -- Highlight surrounding
        replace = 'sr', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`
      },
    },
  },
}
