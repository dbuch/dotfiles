local M = {}

M.root = require 'dbuch.traits.root'

function M.notify(msg)
  vim.notify(msg)
end

---@return boolean
M.is_windows = jit.os:find 'Windows'

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
  -- Quit current buffer if it NOT writeflag
  -- Quit criteria:
  --   if write but emtpy and nofile -> force quit
  --   if #openbuffers <= 1 exit (But prompt?)

  local current_buf = vim.api.nvim_get_current_buf()
  if not vim.bo[current_buf].modified then
    vim.api.nvim_buf_delete(current_buf, {})
  end

  local loaded_buffers = vim.iter(vim.api.nvim_list_bufs()):filter(vim.api.nvim_buf_is_loaded):totable()

  local buf_is_file = function(window)
    local window_buf = vim.api.nvim_win_get_buf(window)
    return vim.bo[window_buf].buftype ~= ''
  end

  local windows = vim.iter(vim.api.nvim_list_wins()):filter(buf_is_file):totable()

  if #loaded_buffers <= 1 then
    vim.cmd 'q'
    return
  end

  if #loaded_buffers - 1 <= 1 then
    vim.notify 'Last buf'
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
---
--- Truncates a string to a specified maximum width and appends an ellipsis character if needed.
--- @param s string: The input string to truncate.
--- @param maxwidth integer: The maximum character width of the string (including the ellipsis if added).
--- @param ellipsis_char string? The ellipsis character to append (defaults to "…").
--- @return string: The truncated string with ellipsis if truncation occurred, or the original string if not.
function string.ellipsize_at(s, maxwidth, ellipsis_char)
  if vim.fn.strchars(s) > maxwidth then
    ellipsis_char = ellipsis_char or '…'
    return vim.fn.strcharpart(s, 0, maxwidth) .. ellipsis_char
  end

  return s
end

return M
