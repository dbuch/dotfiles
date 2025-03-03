-- TODO: https://github.com/yetone/avante.nvim

---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'echasnovski/mini.pick',
    lazy = false,
    version = false,
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
        --link = 'Visual',
        link = 'PmenuExtra',
      })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    opts = {
      debug_mode = false,
      max_file_length = 100000,
      signs = {
        add = { show_count = false },
        change = { show_count = false },
        delete = { show_count = true },
        topdelete = { show_count = true },
        changedelete = { show_count = true },
      },
      preview_config = {
        border = 'rounded',
      },
      count_chars = require('dbuch.icons').subscript_count,
      update_debounce = 50,
      word_diff = true,
      trouble = true,
    },
  },
  {
    'folke/trouble.nvim',
    version = '*',
    opts = { use_diagnostic_signs = true },
    cmd = { 'TroubleToggle', 'Trouble' },
  },
  {
    'akinsho/toggleterm.nvim',
    cmd = 'ToggleTerm',
    opts = {
      shade_terminals = false,
      shell = 'nu',
    },
  },
  {
    'sindrets/diffview.nvim',
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewToggleFiles',
      'DiffviewFocusFiles',
      'DiffviewRefresh',
      'DiffviewFileHistory',
    },
    opts = {},
  },
  {
    'lewis6991/hover.nvim',
    keys = {
      { 'K', '<Cmd>Hover<cr>' },
      { 'gK', '<Cmd>HoverSelect<cr>' },
    },
    ---@module 'hover'
    ---@type Hover.UserConfig
    opts = {
      init = function()
        require 'hover.providers.lsp'
        require 'hover.providers.dictionary'
        require 'hover.providers.fold_preview'
        require 'hover.providers.man'
      end,
      preview_window = true,
    },
    config = function(_plugin, hover_opts)
      require('hover').setup(hover_opts)
      vim.keymap.set('n', 'K', require('hover').hover, { desc = 'hover.nvim' })
      vim.keymap.set('n', 'gK', require('hover').hover_select, { desc = 'hover.nvim (select)' })
    end,
  },
  {
    'echasnovski/mini.colors',
    init = function()
      vim.api.nvim_create_user_command('LoadMiniColors', function()
        vim.cmd 'Lazy load mini.colors'
      end, {})
    end,
    lazy = true,
    version = false,
    config = function()
      require('mini.colors').setup()
    end,
  },
  {
    'echasnovski/mini.files',
    lazy = false,
    version = false,
    opts = {
      content = {
        filter = function(fs_entry)
          ---@type string
          local basename = fs_entry.name
          if basename:sub(0, 1) == '.' then
            if basename:match '%.config' or basename:match '%.git' then
              return true
            end
            return false
          end
          return true
        end,
      },
      windows = {
        max_number = 3,
        preview = false,
      },
    },
  },
  {
    'echasnovski/mini.cursorword',
    event = 'VeryLazy',
    version = false,
    opts = {},
  },
  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'lewis6991/whatthejump.nvim',
    event = 'VeryLazy',
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
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },
    ft = 'markdown',
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      latex = {
        enabled = false,
      },
      indent = {
        enabled = false,
      },
    },
  },
  {
    'brenoprata10/nvim-highlight-colors',
    cmd = { 'HighlightColors' },
    opts = {},
  },
  {
    'mikesmithgh/kitty-scrollback.nvim',
    enabled = true,
    lazy = true,
    cmd = { 'KittyScrollbackGenerateKittens', 'KittyScrollbackCheckHealth' },
    event = { 'User KittyScrollbackLaunch' },
    config = function()
      vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = vim.api.nvim_create_augroup('kitty_scrollback_quit_with_q', { clear = true }),
        pattern = { 'kitty-scrollback' },
        callback = function()
          vim.keymap.set({ 'n' }, 'q', '<Plug>(KsbCloseOrQuitAll)')
          return true
        end,
      })
      require('kitty-scrollback').setup()
    end,
  },
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
        multilines = {
          enabled = false,
        },
        break_line = {
          enabled = true,
          after = 60,
        },
      },
    },
  },
}
