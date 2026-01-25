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

map(
  'n',
  '<leader>T',
  ':ToggleTerm direction=vertical size=100<CR>',
  { nowait = true, silent = true }
)
map('n', '<leader>f', ':Pick files<CR>', { nowait = true, silent = true })
map('n', '<leader>b', ':Pick buffers<CR>', { nowait = true, silent = true })
map('n', '<leader>g', ':Pick grep_live<CR>', { nowait = true, silent = true })
map('n', '<leader>e', ':lua MiniFiles.open()<CR>', { silent = true })
map('n', '<c-q>', Utils.smart_quit, { silent = true })
map('n', 'sw', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('saiw', false, false, false), 'm', false)
end, { expr = true })

map('n', '<leader>v', function()
  local current_win = vim.api.nvim_get_current_win()

  local current_ve =
    vim.api.nvim_get_option_value('virtualedit', { scope = 'local', win = current_win })

  if current_ve == '' then
    vim.api.nvim_set_option_value('virtualedit', 'all', { scope = 'local', win = current_win })
    vim.notify('virtualedit: on')
  else
    vim.api.nvim_set_option_value('virtualedit', '', { scope = 'local', win = current_win })
    vim.notify('virtualedit: off')
  end
end, { expr = true })

map('n', '<leader>w', '<esc>:w<CR>', { noremap = false })

-- Clear search
map('n', '<esc>', ':noh<return><esc>', { silent = true })
map('n', '<esc>^[', '<esc>^[', { silent = true })
map('t', '<esc>', '<C-\\><C-n>', { silent = true })

map('n', '<leader><leader>', '<c-^>')
