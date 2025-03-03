--TODO: https://github.com/SuperBo/fugit2.nvim

---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'echasnovski/mini.pairs',
    version = false,
    event = 'VeryLazy',
    opts = {
      modes = { insert = true, command = true, terminal = false },
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      skip_ts = { 'string' },
      skip_unbalanced = true,
      markdown = true,
    },
  },
  {
    'echasnovski/mini.comment',
    version = false,
    event = 'VeryLazy',
    opts = {},
  },
  {
    'echasnovski/mini.align',
    version = false,
    keys = function(_, keys)
      local plugin = require('lazy.core.config').spec.plugins['mini.align']
      local opts = require('lazy.core.plugin').values(plugin, 'opts', false)
      local mappings = {
        { opts.mappings.start, desc = 'Start align', mode = { 'n', 'v' } },
        { opts.mappings.start_with_preview, desc = 'Start align with Preview', mode = { 'n', 'v' } },
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
        start = 'ga',
        start_with_preview = 'gA',
      },
    },
  },
  {
    'echasnovski/mini.surround',
    version = false,
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
  -- Autocomplete
  {
    'saecki/crates.nvim',
    event = 'BufRead Cargo.toml',
    ---@module "crates.config"
    ---@type crates.UserConfig
    opts = {
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
      completion = {
        coq = {
          enabled = false,
        },
        cmp = {
          enabled = false,
        },
      },
    },
  },
  {
    'saghen/blink.cmp',
    lazy = false,
    version = 'v0.*',
    -- build = 'cargo build --release --target-dir=target',
    dependencies = {
      'echasnovski/mini.icons',
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      cmdline = {
        enabled = true,
        completion = {
          menu = {
            auto_show = true,
          },
        },
      },
      completion = {

        trigger = {
          prefetch_on_insert = true,
        },

        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          update_delay_ms = 100,
          treesitter_highlighting = true,
          window = {
            max_width = math.min(80, vim.o.columns),
            border = 'single',
          },
        },

        ghost_text = {
          enabled = true,
        },

        accept = {
          auto_brackets = {
            enabled = false,
          },
        },

        list = {
          max_items = 20,
          selection = {
            preselect = function(ctx)
              return ctx.mode ~= 'cmdline' and not require('blink.cmp').snippet_active { direction = 1 }
            end,
            auto_insert = function(ctx)
              return ctx.mode ~= 'cmdline'
            end,
          },
          -- selection = function(ctx)
          --   return ctx.mode == 'cmdline' and 'auto_insert' or 'preselect'
          -- end,
        },
        menu = {
          -- border = 'single'
          draw = {
            treesitter = { 'lsp' },
            columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source' } },
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  --- @type string, string, boolean
                  local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                  return kind_icon
                end,
                highlight = function(ctx)
                  --- @type string, string, boolean
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
              },
              source = {
                ellipsis = false,
                text = function(ctx)
                  local map = {
                    ['lsp'] = '[]',
                    ['path'] = '[󰉋]',
                    ['snippets'] = '[]',
                  }

                  return map[ctx.item.source_id]
                end,
                highlight = 'BlinkCmpSource',
              },
            },
          },
        },
      },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },

      sources = {
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer', 'markdown' },
        -- default = { 'lsp', 'path', 'snippets', 'buffer', 'markdown' },

        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100,
          },
          markdown = { name = 'RenderMarkdown', module = 'render-markdown.integ.blink' },
        },
      },

      fuzzy = {
        use_frecency = true,
        use_proximity = true,
        sorts = { 'score', 'sort_text' },
        prebuilt_binaries = {
          download = true,
          force_version = nil,
          force_system_triple = nil,
          extra_curl_args = {},
        },
      },

      keymap = {
        preset = 'enter',

        ['<A-j>'] = { 'select_next', 'fallback' },
        ['<A-k>'] = { 'select_prev', 'fallback' },

        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },

        ['<Tab>'] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          'snippet_forward',
          'fallback',
        },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      },

      snippets = {
        expand = function(snippet)
          vim.snippet.expand(snippet)
        end,
        active = function(filter)
          return vim.snippet.active(filter)
        end,
        jump = function(direction)
          vim.snippet.jump(direction)
        end,
      },

      signature = {
        enabled = true,
      },
    },
  },
  {
    'andymass/vim-matchup',
    event = 'VeryLazy',
    init = function()
      vim.g.matchup_matchparen_offscreen = { method = 'status_manual' }
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_deferred_show_delay = 100
    end,
  },
}
