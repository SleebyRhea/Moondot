moondot_version = 'dev-1.0'

moon = require"moonscript.base"
path = require"pl.path"
file = require"pl.file"
dir  = require"pl.dir"
parse_file = "#{os.getenv 'HOME'}/.moondot"
plugin_dir = "#{os.getenv 'HOME'}/.moondot.d"

require"moondot.obj"

import sandbox, sandbox_export from require"moondot.env"
import emit, run_with_margin from require"moondot.output"
import for_os, coalesce, trim, repath, wordify from require"moondot.utils"
import set, var, Config from require"moondot.obj.config"
import Repo from require"moondot.obj.repo"
import File, Template from require"moondot.obj.file"
import StateObject from require"moondot.obj.stateobject"

flags_allowed = {
  file: "f"
  help: "h"
  version: "V"
  "plugin-dir": 'p'
}

flags_w_values = {
  'setvar'
  'file'
  'plugin-dir'
}

flags, params = require"pl.app".parse_args arg, flags_w_values, flags_allowed
if flags
  if flags['plugin-dir']
    plugin_dir = flags['plugin-dir']

if path.isdir plugin_dir
  package.moonpath = "#{plugin_dir}/?.moon;#{package.moonpath}"
  for file in *dir.getfiles(plugin_dir, "plugin_*.moon")
    file = path.basename file
    plugin = file\gsub "^plugin_([a-zA-Z0-9_-]+).moon$", '%1'
    require "plugin_#{plugin}"
    emit "Loaded plugin #{plugin}"

if flags
  indent = '      '
  if flags.help
    configs = ''
    entry_w = wordify 'entr', 'y', 'ies'
    Config.each (c) ->
      if type(c.value) == 'table'
        configs ..= "  #{c}: Table with #{#c.value} #{entry_w #c.value}\n"
      else
        configs ..= "  #{c}: '#{c.value or 'none'}'\n"

    print trim indent, "
      Moondot
        User configuration file manager written in Moonscript`

      Usage
        moondot [options <values>] VAR=VAL VAR2=VAL2 ...

      Flags
        -h --help         This help text
        -f --file         File to parse (default: ~/.moondot)
        -p --plugin-dir   Set plugin directory (default: ~/.moondot.d/)
        -V --version      Version string

      Plugins
        Moondot supports plugin moonscript files when placed within the currently
        configured plugin directory. By default, said directory is ~/.moondot.d
        and the required file name pattern is plugin_${name}.${extension}

      Configurations
      #{configs}"
    os.exit 0

  if flags.file
    parse_file = flags.file

  if flags.version
    print moondot_version
    os.exit 0

  for p in *params
    key, val = p\match "^([a-zA-Z0-9_-]+)=([a-zA-Z0-9_-]+)$"
    if key and val
      unless set key, val
        Config key, val, (v) -> v

import command from require"moondot.command"
import chomp from require"moondot.utils"

mt = setmetatable
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
  :tostring
  :command
  :string
  :ipairs
  :chomp
  :pairs
  :table

unless path.isfile parse_file
  print"Please supply a .moondot file located at: #{parse_file}"
  os.exit 1

conf, err = moon.loadfile parse_file
if conf
  sandbox conf
else
  print"Please supply a valid .moondot file located at #{parse_file}:\n#{err}"
  os.exit 1

print!

need_update = (o) ->
  emit "#{o}: %{yellow}Needs update"

emit_state = (bool) ->
  switch bool
    when true
      emit "State: %{green}Good"
    when false
      emit "State: %{red}Failed"

emit "Beginning sync run ..."
run_with_margin ->
  StateObject.each (o) ->
    if o.check and o.enforce then
      ok, reason = o\check!
      unless ok
        need_update o
        run_with_margin ->
          emit "Reason: %{yellow}#{reason}%{reset}" if reason
          emit_state o\enforce!
      else
        if o.state
          emit "#{o}: %{green}Good"
        else
          emit "#{o}: %{red}Failed"

emit "Pruning cache ..."
run_with_margin ->
  deleted = 0
  if path.isdir "#{var.cache_dir}/.compiled"
    for cached_path in *dir.getfiles"#{var.cache_dir}/.compiled"
      link_path = repath cached_path\gsub("^#{var.cache_dir}/.compiled/", "")
      unless File.fetch(link_path) or Template.fetch(link_path)
        emit "Found stale cache file: #{cached_path}"
        deleted += 1
        run_with_margin ->
          emit "Deleted cache file: #{cached_path}"
          file.delete cached_path
          if path.link_attrib(link_path) == cached_path
              require"pl.util".executeex "unlink #{link_path}"
              emit "Cleared stale link: #{link_path}"

  unless deleted > 0
    emit "No stale cache files located"
