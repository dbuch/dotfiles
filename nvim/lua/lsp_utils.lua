local api, lsp = vim.api, vim.lsp
local get_clients = vim.lsp.get_clients
local NvimTrait = require 'dbuch.traits.nvim'

local function client_complete()
  --- @param c vim.lsp.Client
  --- @return string
  return vim.tbl_map(function(c)
    return c.name
  end, get_clients())
end

api.nvim_create_user_command('LspRestart', function(kwargs)
  local bufnr = vim.api.nvim_get_current_buf()
  local name = kwargs.fargs[1] --- @type string
  for _, client in ipairs(get_clients { bufnr = bufnr, name = name }) do
    local bufs = vim.deepcopy(client.attached_buffers)
    client:stop()
    vim.wait(30000, function()
      return lsp.get_client_by_id(client.id) == nil
    end)
    local client_id = vim.lsp.start(client.config, {
      bufnr = bufnr,
    })
    if client_id then
      for buf in pairs(bufs) do
        lsp.buf_attach_client(buf, client_id)
      end
    end
  end
end, {
  nargs = '*',
  complete = client_complete,
})

api.nvim_create_user_command('LspStop', function(kwargs)
  local bufnr = vim.api.nvim_get_current_buf()
  local name = kwargs.fargs[1] --- @type string
  for _, client in ipairs(get_clients { bufnr = bufnr, name = name }) do
    client:stop()
  end
end, {
  nargs = '*',
  complete = client_complete,
})

do -- LspLog
  local path = vim.lsp.get_log_path()
  vim.fn.delete(path)
  -- vim.lsp.log.set_level(vim.lsp.log.levels.DEBUG)
  vim.lsp.log.set_format_func(vim.inspect)

  api.nvim_create_user_command('LspLog', function()
    if vim.uv.fs_stat(path) == nil then
      vim.notify 'No lsp log available'
      return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    if not buf then
      return
    end

    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'log'

    local width = vim.o.columns
    local height = vim.o.lines

    local win_width = math.floor(width * 0.8)
    local win_height = math.floor(height * 0.9)
    local col = math.floor((width - win_width) / 2)
    local row = math.floor((height - win_height) / 2)

    local win_opts = {
      style = 'minimal',
      relative = 'editor',
      width = win_width,
      height = win_height,
      row = row,
      col = col,
      border = 'single', -- Other options: "single", "double", etc.
    }

    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.api.nvim_set_current_win(win)

    local content = vim.fn.readfile(path) -- Read log file content

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    NvimTrait.set_close_with_q(buf)
  end, {})
end
