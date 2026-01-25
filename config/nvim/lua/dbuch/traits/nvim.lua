local M = {}

function M.augroup(name)
  return vim.api.nvim_create_augroup('dbuch_' .. name, { clear = true })
end

-- delay notifications till vim.notify was replaced or after 500ms
function M.lazy_notify()
  local notifs = {}
  local function temp(...)
    table.insert(notifs, vim.F.pack_len(...))
  end

  local orig = vim.notify
  vim.notify = temp

  local timer = vim.uv.new_timer()
  local check = assert(vim.uv.new_check())

  local replay = function()
    timer:stop()
    check:stop()
    if vim.notify == temp then
      vim.notify = orig -- put back the original notify if needed
    end
    vim.schedule(function()
      ---@diagnostic disable-next-line: no-unknown
      for _, notif in ipairs(notifs) do
        vim.notify(vim.F.unpack_len(notif))
      end
    end)
  end

  -- wait till vim.notify has been replaced
  check:start(function()
    if vim.notify ~= temp then
      replay()
    end
  end)
  -- or if it took more than 500ms, then something went wrong
  timer:start(500, 0, replay)
end

---@param cb fun(buffer:integer, lang:string)
function M.on_ts_filetype(cb)
  vim.api.nvim_create_autocmd('User', {
    pattern = 'TSFileType',
    callback = function(args)
      local bufnr = args.data.buf
      local lang = args.data.lang
      cb(bufnr, lang)
    end,
  })
end

---@param cb fun(_:vim.lsp.Client, _:integer): boolean?
function M.on_lsp_attach(cb)
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      ---@type integer
      local buffer = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client ~= nil then
        return cb(client, buffer)
      end
    end,
  })
end

---@return boolean
function M.is_file_opened()
  return vim.fn.argc(-1) == 0
end

M.has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0
    and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

function M.inlay_hint_toggle()
  local toggle_value = not vim.lsp.inlay_hint.is_enabled({})
  vim.lsp.inlay_hint.enable(toggle_value)
  return toggle_value
end

---@param bufnr? integer
function M.set_close_with_q(bufnr)
  vim.bo[bufnr].buflisted = false
  vim.keymap.set('n', 'q', '<cmd>close<cr>', {
    buffer = bufnr,
    silent = true,
  })
end

return M
