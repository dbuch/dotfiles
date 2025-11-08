---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    version = '*',
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
      'nvim-mini/mini.icons',
    },
    init = function()
      vim.api.nvim_create_user_command('Git', function()
        Snacks.lazygit.open()
      end, {})

      vim.api.nvim_create_user_command('Slumber', function()
        local cmd = { 'slumber' }
        ---@module "snacks"
        ---@type snacks.terminal.Opts
        local opts = {}

        Snacks.terminal.open(cmd, opts)
      end, {})

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

          if vim.fn.has('nvim-0.11') == 1 then
            vim._print = function(_, ...)
              dd(...)
            end
          else
            vim.print = _G.dd
          end

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
      lazygit = {
        enabled = false,
        configure = true,
        config = {
          os = { editPreset = 'nvim-remote' },
          gui = { nerdFontsVersion = '3' },
        },
      },
      statuscolumn = {
        enabled = false,
        git_hl = true,
        folds = { open = false },
        left = { 'fold', 'sign', 'git' },
        right = { 'mark' },
      },
    },
  },
}
