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
local for_os, coalesce, trim, repath, wordify
do
  local _obj_0 = require("moondot.utils")
  for_os, coalesce, trim, repath, wordify = _obj_0.for_os, _obj_0.coalesce, _obj_0.trim, _obj_0.repath, _obj_0.wordify
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
  if flags['plugin-dir'] then
    plugin_dir = flags['plugin-dir']
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
if flags then
  local indent = '      '
  if flags.help then
    local configs = ''
    local entry_w = wordify('entr', 'y', 'ies')
    Config.each(function(c)
      if type(c.value) == 'table' then
        configs = configs .. "  " .. tostring(c) .. ": Table with " .. tostring(#c.value) .. " " .. tostring(entry_w(#c.value)) .. "\n"
      else
        configs = configs .. "  " .. tostring(c) .. ": '" .. tostring(c.value or 'none') .. "'\n"
      end
    end)
    print(trim(indent, "\n      Moondot\n        User configuration file manager written in Moonscript`\n\n      Usage\n        moondot [options <values>] VAR=VAL VAR2=VAL2 ...\n\n      Flags\n        -h --help         This help text\n        -f --file         File to parse (default: ~/.moondot)\n        -p --plugin-dir   Set plugin directory (default: ~/.moondot.d/)\n        -V --version      Version string\n\n      Plugins\n        Moondot supports plugin moonscript files when placed within the currently\n        configured plugin directory. By default, said directory is ~/.moondot.d\n        and the required file name pattern is plugin_${name}.moon\n\n      Configurations\n      " .. tostring(configs)))
    os.exit(0)
  end
  if flags.file then
    parse_file = flags.file
  end
  if flags.version then
    print(moondot_version)
    os.exit(0)
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
local command
command = require("moondot.command").command
local chomp
chomp = require("moondot.utils").chomp
local mt = setmetatable
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
    return for_os('windows', fn)
  end,
  coalesce = coalesce,
  tostring = tostring,
  command = command,
  string = string,
  ipairs = ipairs,
  chomp = chomp,
  pairs = pairs,
  table = table
})
if not (path.isfile(parse_file)) then
  print("Please supply a .moondot file located at: " .. tostring(parse_file))
  os.exit(1)
end
local conf, err = moon.loadfile(parse_file)
if conf then
  sandbox(conf)
else
  print("Please supply a valid .moondot file located at " .. tostring(parse_file) .. ":\n" .. tostring(err))
  os.exit(1)
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
emit("Pruning cache ...")
return run_with_margin(function()
  local deleted = 0
  if path.isdir(tostring(var.cache_dir) .. "/.compiled") then
    local _list_0 = dir.getfiles(tostring(var.cache_dir) .. "/.compiled")
    for _index_0 = 1, #_list_0 do
      local cached_path = _list_0[_index_0]
      local link_path = repath(cached_path:gsub("^" .. tostring(var.cache_dir) .. "/.compiled/", ""))
      if not (File.fetch(link_path) or Template.fetch(link_path)) then
        emit("Found stale cache file: " .. tostring(cached_path))
        deleted = deleted + 1
        run_with_margin(function()
          emit("Deleted cache file: " .. tostring(cached_path))
          file.delete(cached_path)
          if path.link_attrib(link_path) == cached_path then
            require("pl.util").executeex("unlink " .. tostring(link_path))
            return emit("Cleared stale link: " .. tostring(link_path))
          end
        end)
      end
    end
  end
  if not (deleted > 0) then
    return emit("No stale cache files located")
  end
end)
