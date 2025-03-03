M = {}

---comment
---@param what string
---@return string|string[]|nil
function M.stdpath_normalized(what)
  local path = vim.fn.stdpath(what)
  if path == nil then
    return nil
  end

  if type(path) == 'string' then
    return vim.fs.normalize(path)
  end

  local paths = {}
  for _, value in ipairs(path) do
    path = vim.fs.normalize(value)
    table.insert(paths, path)
  end
  return paths
end

---@type boolean
M.is_unix = vim.uv.os_uname().sysname:match 'Windows' == nil
---@type string|string[]|nil
M.cache_dir = M.stdpath_normalized 'cache'
---@type string|string[]|nil
M.data_dir = M.stdpath_normalized 'data'
---@type string|string[]|nil
M.log_dir = M.stdpath_normalized 'log'
---@type string|string[]|nil
M.undo_dir = M.cache_dir .. '/undodir/'

return M
