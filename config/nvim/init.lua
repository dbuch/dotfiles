vim.loader.enable()

-- Early Configuration
vim.g.loaded_matchit = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

---Safely require a Lua module.
---
---This behaves like `require()`, but prevents hard errors during startup or
---runtime. If the module fails to load, an error notification is shown using
---`vim.notify()`, and `nil` is returned instead of raising an exception.
---
---This is useful when:
---  • Loading optional plugins or dependencies
---  • Loading user configuration modules that may not exist
---  • Avoiding `pcall(require, ...)` boilerplate everywhere
---
---Example:
---```lua
---local mod = safe_require("dbuch")
---if mod then
---  mod.do_something()
---end
---```
---
---@param modname string
---@return any|nil
_G.safe_require = function(modname)
  --- @diagnostic disable-next-line: no-unknown
  local ok, res = pcall(require, modname)
  if not ok then
    vim.notify(('Failed to load `%s`: %s'):format(modname, res), vim.log.levels.ERROR)
    return nil
  end
  return res
end

-- Bootstrap
---@type string
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(lazypath) then
  vim
    .system({
      'git',
      'clone',
      '--filter=blob:none',
      'https://github.com/folke/lazy.nvim.git',
      '--branch=stable', -- latest stable release
      lazypath,
    })
    :wait()
end

vim.opt.rtp:prepend(lazypath)

-- Initialize
safe_require('dbuch')
