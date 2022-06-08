path = require"pl.path"
moon = require"moonscript.base"
require"moondot.obj"

import
  sandbox
  sandbox_export
  from require"moondot.env"

import
  emit
  run_with_margin
  from require"moondot.output"

import
  for_os
  coalesce
  ensure_path_exists
  from require"moondot.utils"

import
  set
  var
  from require"moondot.obj.config"

import
  Repo
  from require"moondot.obj.repo"

import
  File
  Template
  from require"moondot.obj.file"

sandbox_export
  block: (name, fn) ->
    emit "Setting up #{name} ..."
    run_with_margin fn
  macos: (fn) ->
    for_os 'macos', fn
  linux: (fn) ->
    for_os 'linux', fn
  bsd: (fn) ->
    for_os 'bsd', fn
  windows: (fn) ->
    for_os 'bsd', fn
  :coalesce
  :ipairs
  :pairs
  :tostring

unless path.isfile "#{os.getenv 'HOME'}/.moondot"
  print"please supply a .moondot file located at ~/.moondot"
  os.exit 1

if conf = moon.loadfile"#{os.getenv 'HOME'}/.moondot"
  sandbox conf
else
  print"please supply a valid .moondot file located at ~/.moondot"
  os.exit 1

print!

need_update = (o) -> emit "#{o}: %{yellow}Needs update"

emit_state = (bool) ->
  switch bool
    when true
      emit "State: %{green}Good"
    when false
      emit "State: %{red}Failed"

emit "Beginning sync run ..."
run_with_margin ->
  emit "Using cache: #{var.cache_dir}"
  if Repo.count! > 0
      emit "Enforcing repository state ..."
      run_with_margin -> Repo.each (r) ->
        emit "#{r}: Pulling remote"
        run_with_margin ->
          r\enforce!
          emit_state r.state


  if File.count! > 0
      emit "Enforcing file state ..."
      run_with_margin -> File.each (f) ->
        if not f\check!
          need_update f
          run_with_margin -> f\enforce!
        else
          emit "#{f}: %{green}Good"
          return
        run_with_margin -> emit_state f.state

  if Template.count! > 0
    emit "Enforcing template state ..."
    run_with_margin -> Template.each (f) ->
      if not f\check!
        need_update f
        run_with_margin -> f\enforce!
      else
        emit "#{f}: %{green}Good"
        return

      run_with_margin -> emit_state f.state
