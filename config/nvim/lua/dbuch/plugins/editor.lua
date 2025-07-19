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
        link = 'Visual',
        --link = 'PmenuExtra',
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
    ---@module 'trouble'
    ---@type trouble.Config
    opts = {
      use_diagnostic_signs = true,
    },
    cmd = { 'TroubleToggle', 'Trouble' },
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
    'patrickpichler/hovercraft.nvim',

    dependencies = {
      { 'nvim-lua/plenary.nvim' },
    },

    -- this is the default config and can be skipped
    opts = function()
      return {
        providers = {
          providers = {
            {
              'LSP',
              require('hovercraft.provider.lsp.hover').new(),
            },
            {
              'Man',
              require('hovercraft.provider.man').new(),
            },
            {
              'Git Blame',
              require('hovercraft.provider.git.blame').new(),
            },
            {
              'Dictionary',
              require('hovercraft.provider.dictionary').new(),
            },
          },
        },

        window = {
          border = 'single',
        },

        keys = {
          {
            '<C-u>',
            function()
              require('hovercraft').scroll({ delta = -4 })
            end,
          },
          {
            '<C-d>',
            function()
              require('hovercraft').scroll({ delta = 4 })
            end,
          },
          {
            '<TAB>',
            function()
              require('hovercraft').hover_next()
            end,
          },
          {
            '<S-TAB>',
            function()
              require('hovercraft').hover_next({ step = -1 })
            end,
          },
        },
      }
    end,

    keys = {
      {
        'K',
        function()
          local hovercraft = require('hovercraft')
          if hovercraft.is_visible() then
            hovercraft.enter_popup()
          else
            hovercraft.hover()
          end
        end,
      },
    },
  },
  {
    'echasnovski/mini.colors',
    init = function()
      vim.api.nvim_create_user_command('LoadMiniColors', function()
        vim.cmd('Lazy load mini.colors')
      end, {})
    end,
    cmd = 'LoadMiniColors',
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
            if basename:match('%.config') or basename:match('%.git') then
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
    config = function(_, opts)
      local minifiles = require('mini.files')
      minifiles.setup(opts)

      -- Keep track of when the explorer is open to disable format on save.
      local minifiles_explorer_group =
        vim.api.nvim_create_augroup('dbuch/minifiles_explorer', { clear = true })
      vim.api.nvim_create_autocmd('User', {
        group = minifiles_explorer_group,
        pattern = 'MiniFilesExplorerOpen',
        callback = function()
          vim.g.minifiles_active = true
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        group = minifiles_explorer_group,
        pattern = 'MiniFilesExplorerClose',
        callback = function()
          vim.g.minifiles_active = false
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesActionRename',
        callback = function(event)
          Snacks.rename.on_rename_file(event.data.from, event.data.to)
        end,
      })
    end,
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    keys = {
      {
        '<leader>.',
        function()
          Snacks.scratch()
        end,
        desc = 'Toggle Scratch Buffer',
      },
      {
        '<leader>S',
        function()
          Snacks.scratch.select()
        end,
        desc = 'Select Scratch Buffer',
      },
    },
    dependencies = {
      'echasnovski/mini.icons',
    },
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          Snacks.toggle.inlay_hints():map('<leader>i')
        end,
      })
    end,
    ---@module 'snacks'
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      input = { enabled = true },
      terminal = { enabled = true },
      rename = { enabled = true },
      quickfile = { enabled = true },
      styles = {
        input = {
          relative = 'cursor',
          row = -3,
          col = 0,
        },
      },
      image = { enabled = true },
      scratch = { enabled = true },
      scroll = {
        enabled = false,
        animate = {
          duration = { step = 8, total = 80 },
          easing = 'linear',
        },
        animate_repeat = {
          delay = 100,
          duration = { step = 5, total = 50 },
          easing = 'linear',
        },
      },
      words = { enabled = false },
      scope = { enabled = false },
      statuscolumn = {
        enabled = false,
        git_hl = true,
        folds = { open = false },
        left = { 'fold', 'sign', 'git' },
        right = { 'mark' },
      },
    },
  },
  {
    'echasnovski/mini.cursorword',
    event = 'BufReadPost',
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
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'vimwiki' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      file_types = { 'markdown', 'norg', 'rmd', 'org', 'vimwiki' },
      heading = {
        sign = true,
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
      },
      checkbox = { enabled = true },
      completions = {
        blink = {
          enabled = true,
        },
        lsp = {
          enabled = true,
        },
      },
      latex = {
        enabled = false,
      },
      indent = {
        enabled = false,
      },
    },
  },
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
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    opts = {
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
      settings = {
        save_on_toggle = true,
      },
    },
    keys = function()
      local keys = {
        {
          '<leader>H',
          function()
            require('harpoon'):list():add()
          end,
          desc = 'Harpoon File',
        },
        {
          '<leader>h',
          function()
            local harpoon = require('harpoon')
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = 'Harpoon Quick Menu',
        },
      }

      for i = 1, 5 do
        table.insert(keys, {
          '<leader>' .. i,
          function()
            require('harpoon'):list():select(i)
          end,
          desc = 'Harpoon to File ' .. i,
        })
      end
      return keys
    end,
  },
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
