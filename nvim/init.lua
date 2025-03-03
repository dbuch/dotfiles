---@param modname string
---@return boolean|any
_G.safe_require = function(modname)
  local success, module = pcall(require, modname)
  if success then
    return module
  end
  return false
end

_G.Utils = require 'dbuch.utils'

-- Early Configuration
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_gzip = 1
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0

vim.loader.enable()

-- Bootstrap
---@type string
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

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
safe_require 'dbuch'
