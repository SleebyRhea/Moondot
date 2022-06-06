path = require"pl.path"
moon = require"moonscript.base"
require"src.obj"

import
  sandbox
  sandbox_export
  from require"src.env"

import
  emit
  run_with_margin
  from require"src.output"

import
  for_os
  coalesce
  ensure_path_exists
  from require"src.utils"

import
  set
  var
  from require"src.obj.config"

import
  Repo
  from require"src.obj.repo"

import
  File
  Template
  from require"src.obj.file"

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

emit "Beginning sync run ..."
if Repo.count! > 0
  run_with_margin ->
    emit "Enforcing repository state ..."
    run_with_margin -> Repo.each (r) ->
      emit "#{r}: Pulling remote"
      run_with_margin -> r\enforce!

      switch r.state
        when true
          run_with_margin -> emit "State: %{green}Good"
        when false
          run_with_margin -> emit "State: %{red}Failed"

if File.count! > 0
  run_with_margin ->
    emit "Enforcing file state ..."
    run_with_margin -> File.each (f) ->
      if not f\check!
        emit "#{f}: %{yellow}Needs update"
        run_with_margin -> f\enforce!
      else
        emit "#{f}: %{green}Good"
        return

      switch f.state
        when true
          run_with_margin -> emit "State: %{green}Good"
        when false
          run_with_margin -> emit "State: %{red}Failed"

if Template.count! > 0
  run_with_margin ->
  emit "Enforcing template state ..."
  run_with_margin -> Template.each (f) ->
    if not f\check!
      emit "#{f}: Needs update"
      run_with_margin -> f\enforce!
    else
      emit "#{f}: %{green}Good"
      return

    switch f.state
      when trued
        run_with_margin -> emit "State: %{green}Good"
      when false
        run_with_margin -> emit "State: %{red}Failed"
