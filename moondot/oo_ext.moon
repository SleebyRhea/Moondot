-- Builds upon this gist: https://gist.github.com/naartjie/9005e81811c4df6a595b
-- Thanks to naartjie and of course Leafo


--- Create a metatable that is callable with the provided function
-- @param tbl Table to generate metatable from
-- @param fn Function to wrap behind __call
callable = (tbl, fn) ->
  setmetatable tbl, __call: (...) ->
    fn ...

local private

do
  private_data = {}

  private = (cls) ->
    private_data[cls] = setmetatable {}, {__mode: 'k'}
    return private_data[cls]

--- Set a table of fields to be getter objects for the given Class construct
-- @param cls Class whose access is wrapped behind this function
-- @param _getters Read accessible fields
getters = (cls, _getters) ->
  cls.__base.__index = (key) =>
    if type(key) == 'number'
      key = '__number'

    if getter = _getters[key]
      getter @, key
    else
      cls.__base[key]

--- Set a table of fields to be setter objects to the given Class construct
-- @param cls Class whose set access is wrapped behind this function
-- @param _setters Write accessible fields
setters = (cls, _setters) ->
  cls.__base.__newindex = (key, val) =>
    if type(key) == 'number'
      key = '__number'

    if setter = _setters[key]
      setter @, val, key
    else
      rawset @, key, val

--- Raise an error on access with a readonly message
-- @param cls Class being accessed
-- @param key Key being accessed
readonly = (cls, _, key) ->
  error "#{cls.__class.__name}[].#{key} is readonly"

{
  :private
  :getters
  :setters
  :callable
  :readonly
}