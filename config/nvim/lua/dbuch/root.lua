local M = {}

---Normalize a path to an absolute directory.
---Expands ~, $VAR, resolves relative paths.
---@param path string?
---@return string? Fully normalized absolute directory path
local function normalize(path)
  if not path or path == '' then
    return nil
  end

  local normalized = vim.fs.normalize(path)
  local stat = vim.uv.fs_stat(normalized)
  if not stat then
    return nil
  end

  local is_file = stat.type == 'file'
  if is_file then
    normalized = vim.fs.dirname(normalized)
  end

  return normalized
end

local deferred = require('dbuch.deferred')

---@class RooterCallbackArgs
---@field event string
---@field root string|nil

---@class RootCache
---@field private roots table<string,string>
local RootCache = {}
RootCache.__index = RootCache

function RootCache:new()
  return setmetatable({
    roots = {},
  }, RootCache)
end

---@param root string?
---@return string? ---normalized and dirname
function RootCache:add(root)
  local normalized = normalize(root)
  if not normalized or normalized == '' then
    return
  end

  self.roots[normalized] = normalized

  return normalized
end

-- Check descendant
---@param path string
---@param root string
---@return boolean if path is descendant of root
local function is_descendant(path, root)
  return path:sub(1, #root) == root
end

-- Walk upward to nearest cached root (fast)
function RootCache:get(path)
  for cached_root, _ in pairs(self.roots) do
    if is_descendant(path, cached_root) then
      return cached_root
    end
  end

  return nil
end

function RootCache:dump()
  local empty = true
  for root in pairs(self.roots) do
    empty = false
    vim.notify('RootCache: ' .. root, vim.log.levels.INFO)
  end
  if empty then
    vim.notify('RootCache: (empty)', vim.log.levels.INFO)
  end
end

M.root_cache = RootCache:new()
M.root_identifiers = { '.git' }

----------------------------------------------------------
-- Helpers
----------------------------------------------------------

---@param data RooterCallbackArgs
local function emit_rooted(data)
  if data.root == nil then
    return
  end
  vim.api.nvim_exec_autocmds('User', { pattern = 'Rooted', data = data })
end

---@param root string
local function change_root(root)
  local cwd = vim.fn.getcwd()

  if cwd == root then
    return false
  end

  return vim.fn.chdir(root) ~= ''
end

local function resolve_client_root(client)
  if client.config.workspace_folders and #client.config.workspace_folders > 0 then
    return vim.uri_to_fname(client.config.workspace_folders[1].uri)
  end
  return client.config.root_dir
end

----------------------------------------------------------
-- Root resolution
----------------------------------------------------------

---@param buf_num? number
---@return string|nil
function M.resolve_root(buf_num)
  buf_num = buf_num or 0

  local path = vim.api.nvim_buf_get_name(buf_num)
  if path == '' then
    return nil
  end

  local dir_path = normalize(path)

  -- 1. Cache check
  local cached = M.root_cache:get(dir_path)
  if cached then
    return cached
  end

  -- 2. Upward search for markers
  local matches = vim.fs.find(M.root_identifiers, {
    path = dir_path,
    upward = true,
  })

  if not matches or #matches == 0 then
    return nil
  end

  return M.root_cache:add(matches[1])
end

---@private
M._running = {}

function M.setup()
  local augroup = vim.api.nvim_create_augroup('dbuch_rooter', { clear = true })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'Rooted',
    callback = function(args)
      if args.data and args.data.root then
        vim.notify(
          args.data.root:gsub(vim.env.HOME, '~'),
          vim.log.levels.INFO,
          { annote = ('Workspace Directory (%s)'):format(args.data.event) }
        )
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufReadPost', {
    group = augroup,
    callback = function(args)
      local buftype = vim.bo[args.buf].buftype
      if buftype ~= '' or buftype == 'nofile' or buftype == 'prompt' or buftype == 'quickfix' then
        return
      end

      deferred:start(function()
        if not vim.api.nvim_buf_is_valid(args.buf) then
          return
        end

        local clients = vim.lsp.get_clients({ bufnr = args.buf })
        if #clients > 0 then
          for _, client in ipairs(clients) do
            local client_root = resolve_client_root(client)
            if client_root and change_root(client_root) then
              emit_rooted({ event = 'LSP', root = client_root })
              return
            end
          end
          return
        end

        local new_root = M.resolve_root(args.buf)
        if new_root and change_root(new_root) then
          emit_rooted({ event = 'BUF', root = new_root })
        end
      end, 250)
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      deferred:cancel()

      local root = resolve_client_root(client)
      if change_root(root) then
        emit_rooted({ event = 'LSP', root = root })
        M.root_cache:add(root)
      end
    end,
  })
end

function M.dump_cache()
  M.root_cache:dump()
end

return M
