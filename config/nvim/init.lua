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

vim.loader.enable()

local ok, _ = pcall(require, 'dbuch.globals')
if not ok then
  vim.notify('Failed to load globals', vim.log.levels.ERROR)
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
