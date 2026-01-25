vim.opt.backup = true
vim.opt.backupdir:remove('.')
vim.opt.breakindent = true
vim.opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus'
vim.opt.expandtab = true

vim.opt.confirm = true

vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.inccommand = 'split'
vim.opt.conceallevel = 3
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 3
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.scrolloff = 6
vim.opt.sidescroll = 6
vim.opt.sidescrolloff = 6
vim.opt.signcolumn = 'yes'
vim.opt.smartcase = true
vim.opt.smoothscroll = true
vim.opt.softtabstop = 4
vim.opt.startofline = false
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.textwidth = 80
vim.opt.virtualedit:append('block')
vim.opt.winblend = 4
vim.opt.pumblend = 4
vim.opt.pumheight = 10
vim.opt.wrap = false

vim.opt.wildmode = 'longest:full,full'

vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.completeopt:append({
  'noinsert',
  'menuone',
  'noselect',
  'preview',
})

vim.opt.showbreak = '↳ '
vim.opt.mouse = 'a'
vim.opt.mousemodel = 'extend'
vim.opt.mousemoveevent = true
vim.opt.diffopt:append({
  'vertical',
  'foldcolumn:0',
  'indent-heuristic',
})

vim.opt.timeoutlen = 300
vim.opt.updatetime = 200

vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000
vim.opt.undodir = require('dbuch.env').undo_dir

vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.splitkeep = 'screen'

-- formating
vim.g.autoformat = true
vim.opt.formatoptions:append({
  r = true, -- Automatically insert comment leader after <Enter> in Insert mode.
  o = true, -- Automatically insert comment leader after 'o' or 'O' in Normal mode.
  l = true, -- Long lines are not broken in insert mode.
  t = true, -- Do not auto wrap text
  n = true, -- Recognise lists
})

vim.opt.linebreak = true

vim.opt.cmdheight = 0
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.showcmd = false

-- Folding
vim.g.sh_fold_enabled = 1

--stylua: ignore
vim.opt.fillchars = {
  foldopen  = "",
  foldclose = "",
  fold      = " ",
  foldsep   = " ",
  diff      = "╱",
  eob       = " ",
}

-- vim.opt.foldcolumn = 'auto:0'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldopen:append('jump')

vim.wo.foldmethod = 'expr'
vim.wo.foldcolumn = 'auto:1'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- grep
vim.opt.grepformat = '%f:%l:%c:%m'
vim.opt.grepprg = 'rg --vimgrep'

-- session
vim.opt.sessionoptions = { 'buffers', 'curdir', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }

-- nushell
vim.opt.sh = 'nu'
vim.opt.shelltemp = false
vim.opt.shellredir = 'out+err> %s'
vim.opt.shellcmdflag = '--stdin --no-newline -c'

vim.opt.shellxescape = ''
vim.opt.shellxquote = ''
vim.opt.shellquote = ''
