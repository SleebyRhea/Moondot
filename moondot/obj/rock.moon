path = require"pl.path"

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

  luarocks = setmetatable {}, __index: (_, cmd) -> (...) ->
    need_type cmd, 'string', 1

    unless var.luarocks and path.isfile var.luarocks
      return false, 'missing luarocks installation'

    arg_str = ''
    for a in *({...})
      arg_str ..= "#{a} "
    exec_str = "env LUA_PATH= LUA_CPATH= #{var.luarocks} #{cmd} #{arg_str}"

    ok, code, out, err = executeex exec_str
    out = insert_margin "\n#{out}"
    err = insert_margin "\n#{err}"
    unless ok
      err = "#{out}\n#{err}" if out != ''

    return ok, code, out, err

  new: (name, state_tbl) =>
    need_type name, 'string', 1

    if state_tbl
      need_type state_tbl, 'table', 2

      state_tbl.ensure, err_var = valid_input state_tbl.ensure, 'invalid', {
        'present'
        'absent'
      }

      @ensure = state_tbl.ensure
    else
      @ensure = 'present'

    @name = name

    super!

  check: =>
    chk = ->
      return false, "Luarocks variable unset" unless var.luarocks and var.luarocks != 'none'

      ok, code, out, err = luarocks.show @name
      unless ok
        switch code
          when 1
            return false, "Rock #{@name} is not installed"
          else
            return false, insert_margin("Luarocks encountered an error attempting to run: \n#{out}\n#{err}")

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
          ok, code, out, err = luarocks.install @name
          unless ok
            @error "luarocks: #{code}:\n#{insert_margin out}\n#{insert_margin err}"
          emit out
          return true

      when 'absent'
        emit "luarocks-remove #{@name}"
        return run_with_margin ->
          ok, code, out, err = luarocks.remove @name
          unless ok
            @error "luarocks: #{code}:\n#{insert_margin out}\n#{insert_margin err}"
            return false
          emit out
          return true

      else
        return false

sandbox_export { rock: Rock }

{
  :Rock
}