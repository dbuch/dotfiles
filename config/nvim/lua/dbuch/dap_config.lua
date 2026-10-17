-- lua/dap-config/init.lua
local M = {}

function M.setup()
  local ok, dap = pcall(require, 'dap')
  if not ok then
    vim.notify('dap.nvim not found', vim.log.levels.ERROR)
    return
  end

  dap.adapters.lldb = {
    type = 'executable',
    command = '/usr/bin/lldb-dap',
    name = 'lldb',
  }

  dap.adapters.python = {
    type = 'executable',
    command = 'python',
    args = { '-m', 'debugpy.adapter' },
  }

  dap.adapters.nlua = function(callback, config)
    callback({ type = 'server', host = config.host, port = config.port })
  end

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

  dap.adapters.nushell = { type = 'executable', command = 'nu', args = { '--dap' } }
  dap.configurations.nu = {
    name = 'Debug Nushell',
    type = 'nushell',
    request = 'launch',
    program = function()
      return vim.fn.expand('%:p')
    end,
    cwd = function()
      return vim.fn.getcwd()
    end,
    args = function()
      local input = vim.fn.input('Arguments: ')
      return vim.split(input, '%s+', { trimempty = true })
    end,
    -- Enable Nushell's recorded time-travel. timeTravel = true, timeTravelMaxSteps = 10_000, }, { name = "Debug Nushell (stop on entry)", type = "nushell", request = "launch", program = "${file}", cwd = "${workspaceFolder}", args = {}, stopOnEntry = true, timeTravel = true, timeTravelMaxSteps = 10_000, } }
    stopOnEntry = false,
  }

  dap.configurations.rust = { lldb_config }
  dap.configurations.cpp = { lldb_config }
  dap.configurations.c = { lldb_config }

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
