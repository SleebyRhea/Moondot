path = require"pl.path"

import
  emit
  from require"moondot.output"

import
  ensure_path_exists
  from require"moondot.utils"

import
  sandbox_export
  from require"moondot.env"

import
  getters
  setters
  private
  readonly
  from require"moondot.oo_ext"

import
  need_one
  need_type
  from require"moondot.assertions"

import
  StateObject
  from require"moondot.obj.stateobject"

class Config extends StateObject
  data = private @

  getters @,
    value: =>
      data[@].value

  setters @,
    validator: readonly
    value: (want) =>
      data[@].value = data[@].validator want, data[@].value

  new: (name, default, validator) =>
    need_type name, 'string', 1
    need_type default, 2
    need_type validator, 'function', 3

    @name = name
    data[@] = :validator
    @value = default
    super!

var = setmetatable {},
  __index: (_, key) ->
    c = Config.fetch key
    return false if not c
    return c.value


--- Set a valid configuration item to a valid value
-- @param
set = (key, val) ->
  c = Config.fetch key
  return false if not c

  c.value = val

  return true if c.value == val
  return false

Config 'cache_dir', '~/.local/share/moondot_cache',
  (want) ->
    return path.expanduser want

Config 'path', {},
  (want, current) ->
    return current unless type(want) == 'table'
    dehomed = {}
    dehomed[k] = path.expanduser v for k, v in pairs want
    return dehomed

sandbox_export { :set, :var }

{
  :Config
  :set
  :var
}