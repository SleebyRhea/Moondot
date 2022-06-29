local private
private = require("moondot.oo_ext").private
local emit
emit = require("moondot.output").emit
local color = require("ansicolors")
local StateObject
do
  local _class_0
  local data
  local _base_0 = {
    error = function(self, msg)
      return emit("%{red}" .. tostring(self) .. ": " .. tostring(msg))
    end,
    critical_error = function(self, msg)
      self:error(msg)
      return os.exit(1)
    end,
    track = function(self)
      data[self.__class][self.name] = self
    end,
    __inherited = function(self, child)
      data[child.__class] = { }
      data[child.__class].children = { }
      child.__class.__base.__tostring = function(self)
        return tostring(self.__class.__name) .. "[" .. tostring(self.name) .. "]"
      end
      child.__class.count = function()
        return #(data[child.__class].children)
      end
      child.__class.fetch = function(name)
        return data[child.__class][name]
      end
      child.__class.each = function(fn)
        for k, v in pairs(data[child.__class].children) do
          fn(v)
        end
      end
      if not child.__class.__base.enforce then
        child.__class.__base.enforce = function(self)
          self.state = true
          return true
        end
      else
        local child_enforce = child.__class.__base.enforce
        child.__class.__base.enforce = function(self, ...)
          self.state = child_enforce(self, ...)
          return self.state
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      local cls_name = self.__class.__name
      if data[self.__class][self.name] then
        self:critical_error(tostring(cls_name) .. "[" .. tostring(self.name) .. "] - Cannot track a " .. tostring(cls_name) .. " more than once!")
      end
      data[self.__class][self.name] = self
      return table.insert(data[self.__class].children, self)
    end,
    __base = _base_0,
    __name = "StateObject"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  data = private(self)
  StateObject = _class_0
end
return {
  StateObject = StateObject
}
