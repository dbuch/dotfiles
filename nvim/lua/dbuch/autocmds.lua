local api = vim.api
local autocmd = api.nvim_create_autocmd
local NvimTrait = require 'dbuch.traits.nvim'

autocmd('TextYankPost', {
  group = NvimTrait.augroup 'TextYank',
  desc = 'highlight on yank',
  pattern = '*',
  callback = function(_args)
    vim.hl.on_yank {
      higroup = 'Search',
      timeout = 200,
      on_visual = true,
    }
  end,
})

autocmd('VimEnter', {
  group = NvimTrait.augroup 'paru_review',
  callback = function(args)
    local path = args.file
    local is_dir = vim.fn.isdirectory(path)
    local is_tmp = path:sub(1, 5) == '/tmp/'
    if is_dir and is_tmp then
      ---@param p string
      ---@return boolean
      local function has_pkgbuild(p)
        return p:match 'PKGBUILD'
      end
      ---@param pkgbuild_file string
      for pkgbuild_file in vim.iter(vim.fs.dir(path)):filter(has_pkgbuild) do
        vim.cmd('e ' .. pkgbuild_file)
        vim.cmd 'setf sh'
      end
    end
  end,
})

autocmd('VimResized', {
  group = NvimTrait.augroup 'wind_resize',
  command = 'wincmd =',
})

autocmd('BufReadPost', {
  group = NvimTrait.augroup 'last_loc',
  callback = function(args)
    local mark = api.nvim_buf_get_mark(args.buf, '"')
    local lcount = api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd('FileType', {
  group = NvimTrait.augroup 'close_with_q',
  pattern = {
    'qf',
    'help',
    'man',
    'notify',
    'lspinfo',
    'tsplayground',
    'query',
    'DressingSelect',
  },
  callback = function(event)
    NvimTrait.set_close_with_q(event.buf)
  end,
})

autocmd('TermOpen', {
  group = NvimTrait.augroup 'terminal',
  callback = function(args)
    ---@type vim.keymap.set.Opts
    local opts = {
      buffer = args.buf or 0,
    }

    vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  end,
})

local function emit(ev, data)
  ---@type string|nil
  vim.api.nvim_exec_autocmds('User', { pattern = ev, data = data })
end

---@class RooterCallbackArgs
---@field event string
---@field root string
autocmd('LspAttach', {
  group = NvimTrait.augroup 'rooter',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id) ---@type table|nil
    if client == nil then
      return
    end
    local root = client.config.root_dir ---@type string
    if root ~= vim.uv.cwd() then
      if vim.fn.chdir(root) ~= '' then
        ---@type RooterCallbackArgs
        local data = {
          event = 'LSP',
          root = root,
        }
        emit('Rooted', data)
      end
    end
  end,
})

autocmd('User', {
  pattern = 'Rooted',
  callback = function(args)
    ---@type RooterCallbackArgs
    local data = args.data
    if data.root ~= nil then
      -- local setby = event_to_string(data.event)
      vim.notify(data.root:gsub(vim.env.HOME, '~'), vim.log.levels.INFO, {
        annote = ('New Working Directory (%s)'):format(data.event),
      })
    end
  end,
})

autocmd('User', {
  once = true,
  pattern = 'LazyVimStarted',
  callback = function(_args)
    local stats = require('lazy').stats()
    local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
    vim.notify(('It took %s ms to'):format(ms), vim.log.levels.INFO, {
      annote = 'Startup',
    })
  end,
})
