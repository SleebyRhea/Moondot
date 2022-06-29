local callable
callable = function(tbl, fn)
  return setmetatable(tbl, {
    __call = function(...)
      return fn(...)
    end
  })
end
local private
do
  local private_data = { }
  private = function(cls)
    private_data[cls] = setmetatable({ }, {
      __mode = 'k'
    })
    return private_data[cls]
  end
end
local getters
getters = function(cls, _getters)
  cls.__base.__index = function(self, key)
    if type(key) == 'number' then
      key = '__number'
    end
    do
      local getter = _getters[key]
      if getter then
        return getter(self, key)
      else
        return cls.__base[key]
      end
    end
  end
end
local setters
setters = function(cls, _setters)
  cls.__base.__newindex = function(self, key, val)
    if type(key) == 'number' then
      key = '__number'
    end
    do
      local setter = _setters[key]
      if setter then
        return setter(self, val, key)
      else
        return rawset(self, key, val)
      end
    end
  end
end
local readonly
readonly = function(cls, _, key)
  return error(tostring(cls.__class.__name) .. "[]." .. tostring(key) .. " is readonly")
end
return {
  private = private,
  getters = getters,
  setters = setters,
  callable = callable,
  readonly = readonly
}
