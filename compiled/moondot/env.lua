local context = { }
local need_type
need_type = require("moondot.assertions").need_type
local sandbox
local _exp_0 = string.lower(_VERSION)
if "lua 5.1" == _exp_0 then
  sandbox = function(fn)
    need_type(fn, 'function', 1)
    local old_env = _G
    local _G = context
    setfenv(fn, context)
    local ret = {
      fn()
    }
    _G = old_env
    return unpack(ret)
  end
else
  local _ENV = context
  sandbox = function(fn)
    return fn()
  end
end
local sandbox_export
sandbox_export = function(tbl)
  need_type(tbl, 'table', 1)
  for k, v in pairs(tbl) do
    context[k] = v
  end
end
return {
  sandbox_export = sandbox_export,
  sandbox = sandbox
}
