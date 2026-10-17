---Safely require a Lua module.
---
---This behaves like `require()`, but prevents hard errors during startup or
---runtime. If the module fails to load, an error notification is shown using
---`vim.notify()`, and `nil` is returned instead of raising an exception.
---
---This is useful when:
---  • Loading optional plugins or dependencies
---  • Loading user configuration modules that may not exist
---  • Avoiding `pcall(require, ...)` boilerplate everywhere
---
---Example:
---```lua
---local mod = safe_require("dbuch")
---if mod then
---  mod.do_something()
---end
---```
---
---@param modname string
---@return any|nil
_G.safe_require = function(modname)
  --- @diagnostic disable-next-line: no-unknown
  local ok, res = pcall(require, modname)
  if not ok then
    vim.notify(('Failed to require `%s`: %s'):format(modname, res), vim.log.levels.ERROR)
    return nil
  end
  return res
end
