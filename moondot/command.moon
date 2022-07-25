import need_one, need_type from require"moondot.assertions"
import var, set, Config from require"moondot.obj.config"
import executeex from require"pl.utils"
import chomp from require"moondot.utils"

set_cmd_env = (str, env_tbl) ->
  for key, val in pairs env_tbl
    str = "#{key}=#{val} #{str}"
  return "env #{str}"

command = (cmd) ->
  return (...) ->
    need_type cmd, 'string', 1

    arg_str  = ''
    env_vars = {
      LUA_PATH:  ''
      LUA_CPATH: ''
    }

    for a in *({...})
      switch type a
        when 'string'
          arg_str ..= "#{a} "
        when 'table'
          for k, v in pairs a
            env_vars[k] = v

    exec_str = set_cmd_env cmd, env_vars
    if arg_str != '' then exec_str = "#{exec_str} #{arg_str}"

    ok, code, out, err = executeex exec_str
    return chomp out

:command