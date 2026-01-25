local M = {}

---@return boolean
M.is_windows = jit.os:find('Windows')

---@param path string
---@return string
function M.normalize_path(path)
  if path:sub(1, 1) == '~' then
    local home = vim.uv.os_homedir()
    if home ~= nil then
      if home:sub(-1) == '\\' or home:sub(-1) == '/' then
        home = home:sub(1, -2)
      end
      path = home .. path:sub(2)
    end
  end
  path = path:gsub('\\', '/'):gsub('/+', '/')
  return path:sub(-1) == '/' and path:sub(1, -2) or path
end

function M.smart_quit()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local buftype = vim.bo[buf].buftype

  -- Terminals: always close
  if buftype == 'terminal' then
    vim.api.nvim_buf_delete(buf, { force = true })
    return
  end

  if vim.bo[buf].modified then
    vim.ui.select(
      { 'Save and Close', 'Discard Changes', 'Cancel' },
      { prompt = 'Buffer has unsaved changes:' },
      function(choice)
        if choice == 'Save and Close' then
          vim.cmd('write')
          vim.api.nvim_buf_delete(buf, {})
        elseif choice == 'Discard Changes' then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    )
  end
end

--- Truncates a string to a specified maximum width and appends an ellipsis character if needed.
--- @param self string: The input string to truncate.
--- @param maxwidth integer: The maximum character width of the string (including the ellipsis if added).
--- @param ellipsis_char string? The ellipsis character to append (defaults to "…").
--- @return string: The truncated string with ellipsis if truncation occurred, or the original string if not.
function string:ellipsize_at(maxwidth, ellipsis_char)
  if vim.fn.strchars(self) > maxwidth then
    ellipsis_char = ellipsis_char or '…'
    return vim.fn.strcharpart(self, 0, maxwidth) .. ellipsis_char
  end
  return self
end

---@param self string The input string to check.
---@return boolean: if the string is empty or nil
function string:is_empty()
  return self == nil or self == ''
end

return M
