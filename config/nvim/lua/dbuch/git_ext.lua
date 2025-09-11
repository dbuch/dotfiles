---@class GitExt
---@field private toplevel_cache table<string, string>
---@field private ignored_cache table<string, string[]>
local M = {}
M.__index = M

function M.new()
  local self = setmetatable({
    toplevel_cache = {},
    ignored_cache = {},
  }, M)
  return self
end

---@param path string|nil
---@return string|nil
function M:get_toplevel(path)
  path = path or vim.fn.getcwd()
  if self.toplevel_cache[path] ~= nil then
    return self.toplevel_cache[path]
  end

  local result = vim
    .system({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = path, text = true })
    :wait()

  if result.code == 0 and result.stdout then
    local root = vim.trim(result.stdout)
    if root ~= '' then
      self.toplevel_cache[path] = root
      return root
    end
  end

  return nil
end

---
---@param path string|nil toplevel path
---@return string[]
function M:get_ignored_sync(path)
  local toplevel = path or self:get_toplevel(path)

  if self.ignored_cache[toplevel] ~= nil then
    return self.ignored_cache[toplevel]
  end

  local resp = vim
    .system({ 'git', 'ls-files', '-i', '-o', '--exclude-standard' }, { cwd = toplevel, text = true })
    :wait()

  -- If command fails or no output, just return
  if resp.code ~= 0 or not resp.stdout then
    return {}
  end

  local result = {}
  for line in resp.stdout:gmatch('[^\r\n]+') do
    if line ~= '' then
      table.insert(result, line)
    end
  end

  return result
end

return M
