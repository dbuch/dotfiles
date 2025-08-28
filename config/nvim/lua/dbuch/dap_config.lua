-- lua/dap-config/init.lua
local M = {}

function M.setup(dap_module)
  local dap = dap_module or require('dap')
  dap.adapters.lldb = {
    type = 'executable',
    command = 'lldb-vscode',
    name = 'lldb',
  }

  local lldb_config = {
    name = 'Launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
    runInTerminal = false,
  }

  dap.configurations.rust = { lldb_config }
  dap.configurations.cpp = { lldb_config }
  dap.configurations.c = { lldb_config }

  dap.adapters.python = {
    type = 'executable',
    command = 'python',
    args = { '-m', 'debugpy.adapter' },
  }

  dap.configurations.python = {
    {
      type = 'python',
      request = 'launch',
      name = 'Launch file',
      program = '${file}',
      pythonPath = function()
        return 'python'
      end,
    },
  }

  dap.adapters.nlua = function(callback, config)
    callback({ type = 'server', host = config.host, port = config.port })
  end

  dap.configurations.lua = {
    {
      type = 'nlua',
      request = 'attach',
      name = 'Attach to running Neovim instance',
      host = function()
        return '127.0.0.1'
      end,
      port = function()
        return tonumber(vim.fn.input('Port: ', '8086'))
      end,
    },
  }
end

return M
