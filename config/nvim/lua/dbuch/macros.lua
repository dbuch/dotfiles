local M = {}

---@class Macro
---@field register string
---@field content string
local Macro = {}

---@param register string
---@param content string
---@return Macro
function Macro:new(register, content)
  local state = {
    register = register,
    content = content,
    __index = Macro,
  }
  return setmetatable(state, Macro)
end

---@class RecordingEventArgs
---@field event RecordingEvent
---@field register string

---@alias Macros table<string, Macro>

---@type Macros
local macro_store = {}
local macro_mt = {
  __index = function(t, register)
    return rawget(t, register)
  end,

  __newindex = function(t, register, val)
    rawset(t, register, val)
  end,

  __tostring = function(t)
    local result = {}

    ---@cast t Macros
    for reg, register in pairs(t) do
      table.insert(result, ('Register: %s: %s'):format(reg, register))
    end

    return table.concat(result, '\n')
  end,

  remove = function(t, register)
    if rawget(t, register) then
      rawset(t, register, nil)
    end
  end,

  ---@param t table<string, string>
  clear_all = function(t)
    for k in pairs(t) do
      rawset(t, k, nil)
    end
  end,
}

setmetatable(macro_store, macro_mt)

local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup('macros', {})

---@enum RecordingEvent
M.RecordingEvent = {
  Started = 0,
  Ended = 1,
}

---Convert from string to Enum
---@param type string
---@return RecordingEvent
local function parse_RecordingEvent(type)
  if type == 'RecordingEnter' then
    return M.RecordingEvent.Started
  else
    return M.RecordingEvent.Ended
  end
end

---
---@param cb fun(RecordingEventArgs): boolean
function M.on_macro(cb)
  autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
    group = group,
    callback = function(p)
      ---@type RecordingEvent
      local parsed_event = parse_RecordingEvent(p.event)

      ---@type RecordingEventArgs
      local state = {
        event = parsed_event,
        register = vim.fn.reg_recording() or vim.fn.reg_recorded(),
      }

      cb(state)
    end,
  })
end

M.tostring = function()
  local result = {}

  ---@cast macro_store table<string, Macro>
  for reg, macro in pairs(macro_store) do
    table.insert(result, ('Register: %s: %s'):format(reg, vim.fn.keytrans(macro.content)))
  end
  return table.concat(result, '\n')
end

M.on_macro(function(state)
  if state.event == M.RecordingEvent.Ended then
    local recorded_macro = vim.fn.getreg(state.register)

    local macro = Macro:new(state.register, recorded_macro)
    macro_store[state.register] = macro
  end
  return true
end)

vim.api.nvim_create_user_command('Macrolist', function()
  vim.notify(M.tostring())
end, {})

return M
