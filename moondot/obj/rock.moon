path = require"pl.path"
strx = require"pl.stringx"

import need_type from require"moondot.assertions"
import sandbox_export from require"moondot.env"
import valid_input from require"moondot.utils"
import emit, insert_margin, run_with_margin from require"moondot.output"
import executeex from require"pl.utils"
import var, set, Config from require"moondot.obj.config"
import StateObject from require"moondot.obj.stateobject"

class Rock extends StateObject
  Config 'luarocks', 'none',
    (want, current) ->
      return nil unless want != nil
      return current unless type(want) == 'string'
      dehomed = path.expanduser want
      return current unless path.isfile want
      return dehomed

  Config 'luarocks_prefix', 'none',
    (want, current) ->
      return nil unless want != nil
      return current unless type(want) == 'string'
      dehomed = path.expanduser want
      return current unless path.isdir want
      return dehomed

  set_cmd_env = (str, env_tbl) ->
    for key, val in pairs env_tbl
      str = "#{key}=#{val} #{str}"
    return "env #{str}"

  set_var_dirs = (dir_tbl) ->
    str = ''
    for key, val in pairs dir_tbl
      str = "#{str} #{key}=#{val}"
    return str

  luarocks = setmetatable {}, __index: (_, cmd) -> (...) ->
    need_type cmd, 'string', 1

    unless var.luarocks and path.isfile var.luarocks
      return false, 'missing luarocks installation'

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

    exec_str = set_cmd_env "#{var.luarocks} #{cmd}", env_vars
    if arg_str != '' then exec_str = "#{exec_str} #{arg_str}"

    ok, code, out, err = executeex exec_str
    out = insert_margin "\n#{out}"
    err = insert_margin "\n#{err}"
    return ok, code, (out .. err)

  new: (name, state_tbl) =>
    need_type name, 'string', 1

    @name = name
    @ensure = 'present'
    if state_tbl
      need_type state_tbl, 'table', 2
      if state_tbl.ensure
        state_tbl.ensure = valid_input state_tbl.ensure, 'invalid',  { 'present',  'absent' }

      if state_tbl.variable_dirs
        need_type state_tbl.variable_dirs, 'table', 'state_tbl.variable_dirs'
        for k, v in pairs state_tbl.variable_dirs
          need_type k, 'string', 'state_tbl.variable_dirs[key]'
          need_type v, 'string', 'state_tbl.variable_dirs[value]'
          @variable_dirs = state_tbl.variable_dirs

      @ensure = state_tbl.ensure or @ensure

    super!

  check: =>
    chk = ->
      return false, "Luarocks variable unset" unless var.luarocks and var.luarocks != 'none'

      ok, code, out = luarocks.show @name
      unless ok
        switch code
          when 1
            return false, "Rock #{@name} is not installed"
          else
            return false, "Luarocks encountered an error attempting to run:\n#{out}"

      return true, 'Rock is currently installed'

    @state, reason = chk!
    if @ensure == 'absent'
      @state = not @state
      return false, reason

    return @state, reason

  enforce: =>
    return false, "Luarocks variable unset" unless var.luarocks and var.luarocks != 'none'

    switch @ensure
      when 'present'
        emit "luarocks-install #{@name}"
        return run_with_margin ->
          ok, code, out = luarocks.install @name, set_var_dirs(@variable_dirs or {})
          unless ok
            @error "luarocks: #{code}:\n#{out}"
            return false
          emit out
          return true

      when 'absent'
        emit "luarocks-remove #{@name}"
        return run_with_margin ->
          ok, code, out = luarocks.remove @name, set_var_dirs(@variable_dirs or {})
          unless ok
            @error "luarocks: #{code}:\n#{out}"
            return false
          emit out
          return true

      else
        emit "Invalid ensure: #{@ensure}"
        return false

sandbox_export { rock: Rock }

{
  :Rock
}