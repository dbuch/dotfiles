--TODO: https://github.com/SuperBo/fugit2.nvim

---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'echasnovski/mini.ai',
    event = 'BufReadPre',
    config = true,
  },
  {
    'echasnovski/mini.pairs',
    version = false,
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
    'echasnovski/mini.comment',
    version = false,
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
    'echasnovski/mini.align',
    opts = {},
    keys = {
      { 'ga', mode = { 'n', 'v' } },
      { 'gA', mode = { 'n', 'v' } },
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
    tag = 'stable',
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
    --lazy = false,
    event = { 'InsertEnter', 'CmdlineEnter' },
    version = 'v1.*',
    -- build = 'cargo build --release --target-dir=target',
    dependencies = {
      'echasnovski/mini.icons',
      {
        'supermaven-inc/supermaven-nvim',
        dev = true,
        opts = {
          disable_inline_completion = true, -- disables inline completion for use with cmp
          disable_keymaps = true, -- disables built in keymaps for more manual control
          register_cmp = false,
        },
      },
      {
        'huijiro/blink-cmp-supermaven',
      },
    },
    opts_extend = {
      'sources.completion.enabled_providers',
      'sources.compat',
      'sources.default',
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
          show_on_backspace = true,
        },

        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          update_delay_ms = 100,
          treesitter_highlighting = true,
          window = {
            max_width = math.min(80, vim.o.columns),
            border = 'padded',
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
              return ctx.mode ~= 'cmdline'
                and not require('blink.cmp').snippet_active({ direction = 1 })
            end,
            auto_insert = function(ctx)
              return ctx.mode ~= 'cmdline'
            end,
          },
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
        --default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer', 'codecompanion', 'markdown' },
        default = { 'supermaven', 'lazydev', 'lsp', 'path', 'snippets', 'buffer', 'markdown' },

        providers = {
          path = {
            opts = {
              get_cwd = function(_)
                return vim.fn.getcwd()
              end,
            },
          },
          supermaven = {
            name = 'supermaven',
            module = 'blink-cmp-supermaven',
            async = true,
          },
          -- codecompanion = {
          --   enabled = true,
          --   module = 'codecompanion.providers.completion.blink',
          --   name = 'CodeCompanion',
          -- },
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

        ['<C-k>'] = { 'show', 'show_documentation', 'hide_documentation' },
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
  {
    'vxpm/ferris.nvim',
    ft = 'rust',
    opts = {},
  },
  {
    'jiaoshijie/undotree',
    dependencies = 'nvim-lua/plenary.nvim',
    opts = {
      float_diff = true,
      window = {
        winblend = 5,
      },
    },
    keys = {
      { '<leader>u', "<cmd>lua require('undotree').toggle()<cr>" },
    },
  },
}
