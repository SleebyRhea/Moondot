local moondot_version = 'dev-1.0'
local moon = require("moonscript.base")
local path = require("pl.path")
local parse_file = tostring(os.getenv('HOME')) .. "/.moondot"
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
local for_os, coalesce, trim
do
  local _obj_0 = require("moondot.utils")
  for_os, coalesce, trim = _obj_0.for_os, _obj_0.coalesce, _obj_0.trim
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
local flags_allowed = {
  file = "f",
  help = "h",
  usage = "u",
  version = "V"
}
local flags_w_values = {
  'setvar',
  'file'
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
        -h --help        This help text
        -f --file        File to parse (default: ~/.moondot)
        -V --version     Version string
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
return run_with_margin(function()
  emit("Using cache: " .. tostring(var.cache_dir))
  if Repo.count() > 0 then
    emit("Enforcing repository state ...")
    run_with_margin(function()
      return Repo.each(function(r)
        emit(tostring(r) .. ": Pulling remote")
        return run_with_margin(function()
          r:enforce()
          return emit_state(r.state)
        end)
      end)
    end)
  end
  if File.count() > 0 then
    emit("Enforcing file state ...")
    run_with_margin(function()
      return File.each(function(f)
        if not f:check() then
          need_update(f)
          run_with_margin(function()
            return f:enforce()
          end)
        else
          emit(tostring(f) .. ": %{green}Good")
          return 
        end
        return run_with_margin(function()
          return emit_state(f.state)
        end)
      end)
    end)
  end
  if Template.count() > 0 then
    emit("Enforcing template state ...")
    return run_with_margin(function()
      return Template.each(function(f)
        if not f:check() then
          need_update(f)
          run_with_margin(function()
            return f:enforce()
          end)
        else
          emit(tostring(f) .. ": %{green}Good")
          return 
        end
        return run_with_margin(function()
          return emit_state(f.state)
        end)
      end)
    end)
  end
end)
