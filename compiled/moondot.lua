local moondot_version = 'dev-1.0'
local moon = require("moonscript.base")
local path = require("pl.path")
local file = require("pl.file")
local dir = require("pl.dir")
local parse_file = tostring(os.getenv('HOME')) .. "/.moondot"
local plugin_dir = tostring(os.getenv('HOME')) .. "/.moondot.d"
require("moondot.obj")
local sandbox, sandbox_export
do
  local _obj_0 = require("moondot.env")
  sandbox, sandbox_export = _obj_0.sandbox, _obj_0.sandbox_export
end
local emit, run_with_margin
do
  local _obj_0 = require("moondot.output")
  emit, run_with_margin = _obj_0.emit, _obj_0.run_with_margin
end
local for_os, coalesce, trim, repath
do
  local _obj_0 = require("moondot.utils")
  for_os, coalesce, trim, repath = _obj_0.for_os, _obj_0.coalesce, _obj_0.trim, _obj_0.repath
end
local set, var, Config
do
  local _obj_0 = require("moondot.obj.config")
  set, var, Config = _obj_0.set, _obj_0.var, _obj_0.Config
end
local Repo
Repo = require("moondot.obj.repo").Repo
local File, Template
do
  local _obj_0 = require("moondot.obj.file")
  File, Template = _obj_0.File, _obj_0.Template
end
local StateObject
StateObject = require("moondot.obj.stateobject").StateObject
local flags_allowed = {
  file = "f",
  help = "h",
  usage = "u",
  version = "V",
  ["plugin-dir"] = 'p'
}
local flags_w_values = {
  'setvar',
  'file',
  'plugin-dir'
}
local flags, params = require("pl.app").parse_args(arg, flags_w_values, flags_allowed)
if flags then
  local indent = '      '
  if flags.help then
    print(trim(indent, [[      Moondot
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

    ]]))
    os.exit(0)
  end
  if flags.file then
    parse_file = flags.file
  end
  if flags.version then
    print(moondot_version)
    os.exit(0)
  end
  if flags['plugin-dir'] then
    plugin_dir = flags['plugin-dir']
  end
  for _index_0 = 1, #params do
    local p = params[_index_0]
    local key, val = p:match("^([a-zA-Z0-9_-]+)=([a-zA-Z0-9_-]+)$")
    if key and val then
      if not (set(key, val)) then
        Config(key, val, function(v)
          return v
        end)
      end
    end
  end
end
if path.isdir(plugin_dir) then
  package.moonpath = tostring(plugin_dir) .. "/?.moon;" .. tostring(package.moonpath)
  local _list_0 = dir.getfiles(plugin_dir, "plugin_*.moon")
  for _index_0 = 1, #_list_0 do
    local file = _list_0[_index_0]
    file = path.basename(file)
    local plugin = file:gsub("^plugin_([a-zA-Z0-9_-]+).moon$", '%1')
    require("plugin_" .. tostring(plugin))
    emit("Loaded plugin " .. tostring(plugin))
  end
end
sandbox_export({
  block = function(name, fn)
    emit("Setting up " .. tostring(name) .. " ...")
    return run_with_margin(fn)
  end,
  macos = function(fn)
    return for_os('macos', fn)
  end,
  linux = function(fn)
    return for_os('linux', fn)
  end,
  bsd = function(fn)
    return for_os('bsd', fn)
  end,
  windows = function(fn)
    return for_os('bsd', fn)
  end,
  coalesce = coalesce,
  tostring = tostring,
  string = string,
  ipairs = ipairs,
  pairs = pairs,
  table = table
})
if not (path.isfile(parse_file)) then
  print("Please supply a .moondot file located at: " .. tostring(parse_file))
  os.exit(1)
end
do
  local conf = moon.loadfile(parse_file)
  if conf then
    sandbox(conf)
  else
    print("Please supply a valid .moondot file located at " .. tostring(parse_file))
    os.exit(1)
  end
end
print()
local need_update
need_update = function(o)
  return emit(tostring(o) .. ": %{yellow}Needs update")
end
local emit_state
emit_state = function(bool)
  local _exp_0 = bool
  if true == _exp_0 then
    return emit("State: %{green}Good")
  elseif false == _exp_0 then
    return emit("State: %{red}Failed")
  end
end
emit("Beginning sync run ...")
run_with_margin(function()
  return StateObject.each(function(o)
    if o.check and o.enforce then
      local ok, reason = o:check()
      if not (ok) then
        need_update(o)
        return run_with_margin(function()
          if reason then
            emit("Reason: %{yellow}" .. tostring(reason) .. "%{reset}")
          end
          return emit_state(o:enforce())
        end)
      else
        if o.state then
          return emit(tostring(o) .. ": %{green}Good")
        else
          return emit(tostring(o) .. ": %{red}Failed")
        end
      end
    end
  end)
end)
if path.isdir(tostring(var.cache_dir) .. "/.compiled") then
  local _list_0 = dir.getfiles(tostring(var.cache_dir) .. "/.compiled")
  for _index_0 = 1, #_list_0 do
    local cached_name = _list_0[_index_0]
    local link_name = repath(cached_name)
    if path.link_attrib(link_name) == cached_name then
      if not (File.fetch(link_name) or Template.fetch(link_name)) then
        file.delete(cached_name)
        emit("Cleared stale cache file: " .. tostring(cached_name))
        require("pl.util").executeex("unlink " .. tostring(link_name))
        emit("Cleared stale link: " .. tostring(link_name))
      end
    end
  end
end
