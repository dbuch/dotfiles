---@class Deferred
---@field private _timer uv_timer_t|nil
---@field private _running boolean
---@field private _buf integer|nil
local Deferred = {}
Deferred.__index = Deferred

---Create a new deferred task
---@param fn fun() The function to run
---@param timeout integer Delay in milliseconds
---@param buf? integer Optional buffer ID (for tracking per-buffer)
function Deferred.new(fn, timeout, buf)
  local self = setmetatable({
    _timer = nil,
    _running = false,
    _buf = buf,
  }, Deferred)

  self:start(fn, timeout)
  return self
end

---Start (or restart) the deferred function
---@param fn fun()
---@param timeout integer
function Deferred:start(fn, timeout)
  self:cancel() -- cancel any previous timer
  self._running = true
  self._timer = vim.defer_fn(function()
    fn()
    self._running = false
    self._timer = nil
  end, timeout)
end

---Cancel a pending deferred call (if active)
function Deferred:cancel()
  if self._timer and self._running then
    pcall(vim.uv.timer_stop, self._timer)
    pcall(vim.uv.close, self._timer)
    self._timer = nil
    self._running = false
  end
end

---Check if the deferred task is active
---@return boolean
function Deferred:is_running()
  return self._running
end

---Optional: check if this task is tied to a buffer
---@param buf integer
---@return boolean
function Deferred:matches_buf(buf)
  return self._buf ~= nil and self._buf == buf
end

return Deferred
