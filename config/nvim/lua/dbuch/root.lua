local M = {}
---
---@class RooterCallbackArgs
---@field event string
---@field root string|nil

M.root_cache = {}

M.root_identifiers = { '.git' }

---@param data RooterCallbackArgs
local function emit_rooted(data)
  if data.root == nil then
    return
  end
  ---@type string|nil
  vim.api.nvim_exec_autocmds('User', { pattern = 'Rooted', data = data })
end

---@param root string|nil
local function change_root(root)
  if root == nil then
    return false
  end

  local current_cwd = vim.fn.getcwd()

  if current_cwd == root then
    return false
  end

  return vim.fn.chdir(root) ~= ''
end

---@param buf_num? number
---@return string|nil
function M.resolve_root(buf_num)
  buf_num = buf_num or 0

  local path = vim.api.nvim_buf_get_name(buf_num)

  if path == '' then
    return
  end

  local dir_path = vim.fs.dirname(path)
  local root = M.root_cache[dir_path]
  if root ~= nil then
    return root
  end

  local file_identifier = vim.fs.find(M.root_identifiers, { path = dir_path, upward = true })[1]
  if file_identifier ~= nil then
    root = vim.fs.dirname(file_identifier)
  end

  if type(root) ~= 'string' then
    return
  end

  if vim.fn.isdirectory(root) == 0 then
    return
  end

  root = vim.fs.normalize(vim.fn.fnamemodify(root, ':p'))

  M.root_cache[dir_path] = root
  return root
end

function M.setup()
  local augroup = vim.api.nvim_create_augroup('dbuch_rooter', { clear = true })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'Rooted',
    callback = function(args)
      local data = args.data
      if data and data.root then
        vim.notify(data.root:gsub(vim.env.HOME, '~'), vim.log.levels.INFO, {
          annote = ('New Working Directory (%s)'):format(data.event),
        })
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    callback = function(args)
      if args.file == nil or args.file == '' then
        return
      end

      local attached_clients = vim.lsp.get_clients({ bufnr = args.buf })

      -- Only apply if no LSP is attached for this buffer
      local has_lsp = #attached_clients <= 0
      if has_lsp then
        return
      end

      local new_root = M.resolve_root(args.buf)

      if new_root == nil then
        return
      end

      if change_root(new_root) then
        emit_rooted({
          event = 'BUF',
          root = new_root,
        })
      end
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
      ---@type vim.lsp.Client|nil
      local client = vim.lsp.get_client_by_id(args.data.client_id) ---@type table|nil
      if client == nil then
        return
      end

      ---@type string|nil
      local root = nil
      if client.config.workspace_folders ~= nil and #client.config.workspace_folders > 0 then
        root = client.config.workspace_folders[1].uri
      else
        root = client.config.root_dir
      end

      if change_root(root) then
        emit_rooted({
          event = 'LSP',
          root = root,
        })
      end
    end,
  })
end

return M
