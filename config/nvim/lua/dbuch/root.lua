local M = {}

---Normalize a path to a fully absolute directory.
---
---This performs:
---  • Expansion of "~" and environment variables such as "$VAR"
---  • Path normalization (slashes, ".", "..", Windows paths)
---  • Conversion to an absolute path
---  • Resolution of files to their containing directory
---  • Ensuring the returned directory ends with a trailing "/"
---
---If the path does not exist on disk, the function returns nil.
---
---Examples:
---   normalize_dir("~/config")        --> "/home/user/config/"
---   normalize_dir("foo/../bar.txt")  --> "/cwd/bar/"
---   normalize_dir("/tmp/file")       --> "/tmp/"
---
---@param path string|nil Path to normalize.
---@return string? absolute_dir Fully normalized absolute directory path,
---or nil if the path does not exist.
local function normalize_dir(path)
  if path == nil then
    return nil
  end

  path = vim.fs.normalize(path)
  path = vim.fs.abspath(path)

  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end

  local is_file = stat.type == 'file'
  if is_file then
    path = vim.fs.dirname(path)
  end

  if path:sub(-1) ~= '/' then
    path = path .. '/'
  end

  return path
end

local function current_cwd()
  return normalize_dir(vim.fn.getcwd())
end

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

---@param root string
---@return string? ---normalized and dirname
function RootCache:add(root)
  local normalized = normalize_dir(root)
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

---@type RootCache
---@private
M.cache = RootCache:new()

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
  local cwd = current_cwd()

  if cwd == root then
    return false
  end

  return vim.fn.chdir(root) ~= ''
end

---@param client vim.lsp.Client
---@return string?
local function resolve_client_root(client)
  local workspace_capability = client.server_capabilities.workspace

  ---@type lsp.WorkspaceFolder[]?
  local workspace_folders = client.config.workspace_folders

  if
    workspace_capability
    and workspace_capability.workspaceFolders
    and workspace_folders
    and workspace_folders[1]
    and workspace_folders[1].uri
  then
    return normalize_dir(vim.uri_to_fname(workspace_folders[1].uri))
  end

  if client.config.root_dir then
    return normalize_dir(client.config.root_dir)
  end
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

  local dir_path = normalize_dir(path)

  local cached = M.cache:get(dir_path)
  if cached then
    return cached
  end

  local matches = vim
    .iter(vim.fs.find(M.root_identifiers, {
      path = dir_path,
      upward = true,
    }))
    :find(function(root)
      return vim.endswith(root, '.git') == false
    end)

  if not matches or #matches == 0 then
    return nil
  end

  local root = matches[1]
  return M.cache:add(root)
end

---@private
M._running = {}

---@private
M._git = require('dbuch.git').new()

function M.setup()
  local augroup = vim.api.nvim_create_augroup('dbuch_rooter', { clear = true })
  local deferred = require('dbuch.deferred')

  vim.api.nvim_create_autocmd('User', {
    pattern = 'Rooted',
    callback = function(args)
      if args.data and args.data.root then
        vim.notify(
          args.data.root:gsub(vim.env.HOME, '~'),
          vim.log.levels.INFO,
          { annotate = ('Workspace Directory (%s)'):format(args.data.event) }
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

      if #vim.lsp.get_clients({ bufnr = args.buf }) > 0 then
        return
      end

      -- Give a chance to LspAttach to fire before we proceed with git
      deferred:start(500, function()
        if not vim.api.nvim_buf_is_valid(args.buf) then
          return
        end

        if #vim.lsp.get_clients({ bufnr = args.buf }) > 0 then
          return
        end

        local new_root = M.resolve_root(args.buf)
        if new_root and change_root(new_root) then
          emit_rooted({ event = 'BUF', root = new_root })
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      if client:is_stopped() then
        return
      end

      deferred:cancel()
      local root = resolve_client_root(client)
      if root and change_root(root) then
        emit_rooted({ event = 'LSP', root = root })
        M.cache:add(root)
      end
    end,
  })
end

function M.dump_cache()
  M.cache:dump()
end

return M
