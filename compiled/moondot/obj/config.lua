local path = require("pl.path")
local sandbox_export
sandbox_export = require("moondot.env").sandbox_export
local getters, setters, private, readonly
do
  local _obj_0 = require("moondot.oo_ext")
  getters, setters, private, readonly = _obj_0.getters, _obj_0.setters, _obj_0.private, _obj_0.readonly
end
local need_type
need_type = require("moondot.assertions").need_type
local StateObject
StateObject = require("moondot.obj.stateobject").StateObject
local Config
do
  local _class_0
  local data
  local _parent_0 = StateObject
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, name, default, validator)
      need_type(name, 'string', 1)
      need_type(default, 2)
      need_type(validator, 'function', 3)
      self.name = name
      data[self] = {
        validator = validator
      }
      self.value = default
      return _class_0.__parent.__init(self)
    end,
    __base = _base_0,
    __name = "Config",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  data = private(self)
  getters(self, {
    value = function(self)
      return data[self].value
    end
  })
  setters(self, {
    validator = readonly,
    value = function(self, want)
      data[self].value = data[self].validator(want, data[self].value)
    end
  })
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Config = _class_0
end
local var = setmetatable({ }, {
  __index = function(_, key)
    local c = Config.fetch(key)
    if not c then
      return false
    end
    return c.value
  end
})
local set
set = function(key, val)
  local c = Config.fetch(key)
  if not c then
    return false
  end
  c.value = val
  if c.value == val then
    return true
  end
  return false
end
Config('cache_dir', '~/.local/share/moondot_cache', function(want)
  return path.expanduser(want)
end)
Config('path', { }, function(want, current)
  if not (type(want) == 'table') then
    return current
  end
  local dehomed = { }
  for k, v in pairs(want) do
    dehomed[k] = path.expanduser(v)
  end
  return dehomed
end)
sandbox_export({
  set = set,
  var = var
})
return {
  Config = Config,
  set = set,
  var = var
}
