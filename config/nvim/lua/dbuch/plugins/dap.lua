---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'mfussenegger/nvim-dap',
    keys = {
      { '<leader>d', '', desc = '+debug', mode = { 'n', 'v' } },
      {
        '<leader>dB',
        function()
          require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end,
        desc = 'Breakpoint Condition',
      },
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Toggle Breakpoint',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'Continue',
      },
      {
        '<leader>dC',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Run to Cursor',
      },
      {
        '<leader>dg',
        function()
          require('dap').goto_()
        end,
        desc = 'Go to Line (No Execute)',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = 'Step Into',
      },
      {
        '<leader>dj',
        function()
          require('dap').down()
        end,
        desc = 'Down',
      },
      {
        '<leader>dk',
        function()
          require('dap').up()
        end,
        desc = 'Up',
      },
      {
        '<leader>dl',
        function()
          require('dap').run_last()
        end,
        desc = 'Run Last',
      },
      {
        '<leader>do',
        function()
          require('dap').step_out()
        end,
        desc = 'Step Out',
      },
      {
        '<leader>dO',
        function()
          require('dap').step_over()
        end,
        desc = 'Step Over',
      },
      {
        '<leader>dp',
        function()
          require('dap').pause()
        end,
        desc = 'Pause',
      },
      {
        '<leader>dr',
        function()
          require('dap').repl.toggle()
        end,
        desc = 'Toggle REPL',
      },
      {
        '<leader>ds',
        function()
          require('dap').session()
        end,
        desc = 'Session',
      },
      {
        '<leader>dt',
        function()
          require('dap').terminate()
        end,
        desc = 'Terminate',
      },
      {
        '<leader>dw',
        function()
          require('dap.ui.widgets').hover()
        end,
        desc = 'Widgets',
      },
    },
    dependencies = {
      {
        'theHamsta/nvim-dap-virtual-text',
        opts = {},
      },
    },
    config = function(plugin, opts)
      vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })

      vim.fn.sign_define(
        'DapBreakpoint',
        { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' }
      )
      vim.fn.sign_define(
        'DapBreakpointCondition',
        { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' }
      )
      vim.fn.sign_define(
        'DapBreakpointRejected',
        { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' }
      )
      vim.fn.sign_define(
        'DapLogPoint',
        { text = '󰌑', texthl = 'DiagnosticHint', linehl = '', numhl = '' }
      )
      vim.fn.sign_define(
        'DapStopped',
        { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' }
      )

      require('dbuch.dap_config').setup(require('dap'))
    end,
  },
  {
    'igorlfs/nvim-dap-view',
    cmd = {
      -- Opens both nvim-dap-view windows1: views + console.
      'DapViewOpen',
      -- Closes the views window. Accepts a bang (i.e., DapViewClose!) to also hide the terminal window.
      'DapViewClose',
      -- Behaves like DapViewOpen if there's no views window. Else behaves like DapViewClose (also accepts a bang to behave like DapViewClose!).
      'DapViewToggle',
      -- In normal mode, adds the expression under the cursor to the watch list (see caveats ). In visual mode, adds the selection to the watch list. Also accepts adding an expression directly (i.e., :DapViewWatch foo + bar), which takes precedence.
      'DapViewWatch',
      -- Shows a given view and jumps to its window. For instance, to jump to the REPL, you can use :DapViewJump repl.
      'DapViewJump',
      -- Shows a given view. If the specified view is already the current one, jumps to its window.
      'DapViewShow',
    },
    ---@module 'dap-view'
    ---@type dapview.Config
    opts = {},
  },
}
