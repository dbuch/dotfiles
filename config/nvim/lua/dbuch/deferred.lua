---@class Deferred
---@field private _timer uv_timer_t|nil
---@field private _running boolean
---@field private _buf integer|nil
local Deferred = {}
Deferred.__index = Deferred

---Create a new deferred task
---@param fn fun() The function to run
---@param timeout integer Delay in milliseconds
function Deferred.new(fn, timeout)
  local self = setmetatable({
    _timer = nil,
    _running = false,
  }, Deferred)

  self:start(timeout, fn)
  return self
end

---Start (or restart) the deferred function
---@param timeout integer in milliseconds
---@param fn fun()
function Deferred:start(timeout, fn)
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

return Deferred
