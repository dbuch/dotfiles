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

function M.smart_q()
  -- Quit current buffer if it NOT writeflag
  -- Quit criteria:
  --   if write but emtpy and nofile -> force quit
  --   if #openbuffers <= 1 exit (But prompt?)

  local current_buf = vim.api.nvim_get_current_buf()
  if not vim.bo[current_buf].modified then
    vim.api.nvim_buf_delete(current_buf, {})
  end

  local loaded_buffers =
    vim.iter(vim.api.nvim_list_bufs()):filter(vim.api.nvim_buf_is_loaded):totable()

  local buf_is_file = function(window)
    local window_buf = vim.api.nvim_win_get_buf(window)
    return vim.bo[window_buf].buftype ~= ''
  end

  local windows = vim.iter(vim.api.nvim_list_wins()):filter(buf_is_file):totable()

  if #loaded_buffers <= 1 then
    vim.cmd('q')
    return
  end

  if #loaded_buffers - 1 <= 1 then
    vim.notify('Last buf')
  end

  -- local valid_buf = function(window)
  --   if not vim.api.nvim_win_is_valid(window) then
  --     return false
  --   end
  --
  --   local buffer = vim.api.nvim_win_get_buf(window)
  --   return vim.bo[buffer].buftype == ''
  -- end
  --
  -- local open_windows = vim.iter(vim.api.nvim_list_wins()):filter(valid_buf):totable()
  -- if #open_windows == 1 then
  --   vim.cmd 'q'
  --   return
  -- end
  --
  -- local window = vim.api.nvim_get_current_win()
  -- vim.api.nvim_win_close(window, false)
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
