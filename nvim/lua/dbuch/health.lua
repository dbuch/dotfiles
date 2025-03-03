local M = {}
M.check = function()
  vim.health.start 'dbuch'

  if vim.fn.has 'nvim-0.11.0' == 1 then
    vim.health.ok 'Using Neovim >= 0.11.0'
    for _, cmd in ipairs { 'git', 'rg', 'fd', 'just', 'ruff', 'taplo', 'clang', 'nu' } do
      local name = type(cmd) == 'string' and cmd or vim.inspect(cmd)
      local commands = type(cmd) == 'string' and { cmd } or cmd
      ---@cast commands string[]
      local found = false

      for _, c in ipairs(commands) do
        if vim.fn.executable(c) == 1 then
          name = c
          found = true
        end
      end

      if found then
        vim.health.ok(('`%s` is installed'):format(name))
      else
        vim.health.warn(('`%s` is not installed'):format(name))
      end
    end
  else
    vim.health.error 'Neovim >= 0.11.0 is required'
  end
end
return M
