local need_one, need_type
do
  local _obj_0 = require("moondot.assertions")
  need_one, need_type = _obj_0.need_one, _obj_0.need_type
end
local var, set, Config
do
  local _obj_0 = require("moondot.obj.config")
  var, set, Config = _obj_0.var, _obj_0.set, _obj_0.Config
end
local executeex
executeex = require("pl.utils").executeex
local chomp
chomp = require("moondot.utils").chomp
local set_cmd_env
set_cmd_env = function(str, env_tbl)
  for key, val in pairs(env_tbl) do
    str = tostring(key) .. "=" .. tostring(val) .. " " .. tostring(str)
  end
  return "env " .. tostring(str)
end
local command
command = function(cmd)
  return function(...)
    need_type(cmd, 'string', 1)
    local arg_str = ''
    local env_vars = {
      LUA_PATH = '',
      LUA_CPATH = ''
    }
    local _list_0 = ({
      ...
    })
    for _index_0 = 1, #_list_0 do
      local a = _list_0[_index_0]
      local _exp_0 = type(a)
      if 'string' == _exp_0 then
        arg_str = arg_str .. tostring(a) .. " "
      elseif 'table' == _exp_0 then
        for k, v in pairs(a) do
          env_vars[k] = v
        end
      end
    end
    local exec_str = set_cmd_env(cmd, env_vars)
    if arg_str ~= '' then
      exec_str = tostring(exec_str) .. " " .. tostring(arg_str)
    end
    local ok, code, out, err = executeex(exec_str)
    return chomp(out)
  end
end
return {
  command = command
}
