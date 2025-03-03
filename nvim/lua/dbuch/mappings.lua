-- local NvimTrait = require 'dbuch.traits.nvim'

local map = vim.keymap.set

map('n', '<C-d>', '<C-d>zz', { remap = false })
map('n', '<C-u>', '<C-u>zz', { remap = false })

map('n', 'n', 'nzz', { remap = false })
map('n', 'N', 'Nzz', { remap = false })

map('n', 'L', '$')
map('', 'L', '$')
map('n', 'H', '^')
map('', 'H', '^')

map('n', 'Y', 'y$')

map({ 'n', 's', 'v' }, 'æ', ':')
map({ 'n', 'i', 'v', 's' }, 'Æ', ';')

--map('n', 'q', '<nop>')
map('n', 'j', 'v:count ? "j" : "gj"', { expr = true })
map('n', 'k', 'v:count ? "k" : "gk"', { expr = true })
map('n', '|', [[!v:count ? "<C-W>v<C-W><Right>" : '|']], { expr = true, silent = true })
map('n', '_', [[!v:count ? "<C-W>s<C-W><Down>"  : '_']], { expr = true, silent = true })

map('n', '<leader>T', ':ToggleTerm direction=vertical size=100<CR>', { nowait = true, silent = true })
map('n', '<leader>f', ':Pick files<CR>', { nowait = true, silent = true })
map('n', '<leader>b', ':Pick buffers<CR>', { nowait = true, silent = true })
map('n', '<leader>g', ':Pick grep_live<CR>', { nowait = true, silent = true })
map('n', '<leader>e', ':lua MiniFiles.open()<CR>', { silent = true })
map('n', '<c-q>', Utils.smart_quit, { silent = true })
map('n', 'sw', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('saiw', false, false, false), 'm', false)
end, { expr = true })

-- NvimTrait.on_lsp_attach(function(client, buf)
--   map('n', 'ca', vim.lsp.buf.code_action, { silent = true, buffer = buf })
--   map('n', 'cd', ':Trouble lsp_definitions<CR>', { silent = true, buffer = buf })
--   map('n', 'cn', vim.lsp.buf.rename, { silent = true, buffer = buf })
--   map('n', 't', ':Trouble diagnostics toggle<CR>', { silent = true, buffer = buf })
--   map('n', 'cr', ':Trouble lsp toggle<CR>', { silent = true, buffer = buf })
--   map('n', '<leader>i', function()
--     if client.server_capabilities.inlayHintProvider then
--       local enabled = require('dbuch.traits.nvim').inlay_hint_toggle()
--       vim.notify(string.format('%s %s inlay hints!', client.name, enabled and 'enabled' or ' disabled'))
--     else
--       vim.notify(client.name .. ' doesnt support inlay hints')
--     end
--   end, { silent = true, buffer = buf })
-- end)

map('n', '<leader>w', '<esc>:w<CR>', { noremap = false })

-- Clear search
map('n', '<esc>', ':noh<return><esc>', { silent = true })
map('n', '<esc>^[', '<esc>^[', { silent = true })
map('t', '<esc>', '<C-\\><C-n>', { silent = true })

map('n', '<leader><leader>', '<c-^>')
