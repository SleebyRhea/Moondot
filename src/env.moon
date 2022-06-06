context = {}

import
  need_type
  from require"src.assertions"

sandbox = (fn) ->
  need_type fn, 'function', 1

  old_env = _G
  _G = context
  setfenv fn, context
  ret = {fn!}
  _G = old_env
  return unpack ret

--- Export
sandbox_export = (tbl) ->
  need_type tbl, 'table', 1

  for k, v in pairs tbl
    context[k] = v

{
  :sandbox_export
  :sandbox
}