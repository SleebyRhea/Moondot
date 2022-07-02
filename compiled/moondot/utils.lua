local lfs = require("lfs")
local dir = require("pl.dir")
local strx = require("pl.stringx")
local path = require("pl.path")
local file = require("pl.file")
local emit
emit = require("moondot.output").emit
local executeex
executeex = require("pl.utils").executeex
local need_one, need_type
do
  local _obj_0 = require("moondot.assertions")
  need_one, need_type = _obj_0.need_one, _obj_0.need_type
end
local valid_input
valid_input = function(want, fallback, tbl)
  need_type(tbl, 'table', 3)
  for _, value in ipairs(tbl) do
    if want == value then
      return want, nil
    end
  end
  return fallback, want
end
local depath
depath = function(filepath)
  need_type(filepath, 'string', 1)
  return strx.replace(filepath, path.sep, "@")
end
local repath
repath = function(depathed)
  need_type(depathed, 'string', 1)
  return strx.replace(depathed, "@", path.sep)
end
local coalesce
coalesce = function(t1, t2)
  need_type(t1, 'table', 1)
  need_type(t2, 'table', 2)
  local res = { }
  for k, v in pairs(t2) do
    res[k] = v
  end
  for k, v in pairs(t1) do
    res[k] = v
  end
  return res
end
local for_os
local current_os_type
do
  local ok, _, err
  ok, _, current_os_type, err = executeex("uname")
  assert(ok, "Failed to execute uname to determine operating system: " .. tostring(err))
  current_os_type = current_os_type:gsub('[\r\n]', '')
  current_os_type = string.lower(current_os_type)
  for_os = function(os, fn, ...)
    need_type(os, 'string', 1)
    need_type(fn, 'function', 2)
    local _exp_0 = string.lower(os)
    if 'macos' == _exp_0 or 'darwin' == _exp_0 or 'osx' == _exp_0 then
      if current_os_type == 'darwin' then
        return fn(...)
      end
    elseif 'linux' == _exp_0 then
      if current_os_type == 'linux' then
        return fn(...)
      end
    elseif 'bsd' == _exp_0 then
      if current_os_type == 'bsd' then
        return fn(...)
      end
    end
    return false
  end
end
local make_symlink
make_symlink = function(target, destination)
  need_type(target, 'string', 1)
  need_type(destination, 'string', 2)
  local _exp_0 = current_os_type
  if 'darwin' == _exp_0 or 'linux' == _exp_0 or 'bsd' == _exp_0 then
    emit("Linking " .. tostring(destination) .. " -> " .. tostring(target))
    local ok, code, out, err = executeex("ln -sf " .. tostring(target) .. " " .. tostring(destination))
    if not (ok) then
      error("make_symlink: ln returned code " .. tostring(code) .. ":\n" .. tostring(out) .. "\n" .. tostring(err) .. "\n")
    end
    return true
  else
    return false, "Symlinking is unsupported on " .. tostring(current_os_type) .. " at this time"
  end
  return false, "Unexpected execution path (reached end of make_symlink)"
end
local is_symlink
is_symlink = function(fpath)
  need_type(fpath, 'string', 1)
  local attr = lfs.attributes(fpath)
  local link = lfs.symlinkattributes(fpath)
  if link and link.target then
    return true
  end
  if not (attr or link) then
    return false
  end
  return (attr.dev ~= link.dev or attr.ino ~= link.ino)
end
local ensure_path_exists
ensure_path_exists = function(fpath)
  if not path.exists(fpath) then
    local ok, err = dir.makepath(fpath)
    if not (ok) then
      return nil, err
    end
  end
  return true
end
local trim
trim = function(indent, str)
  local new_str, str_lines = '', strx.splitlines(str)
  for i, line in ipairs(str_lines) do
    local _continue_0 = false
    repeat
      if i == 1 and line:match("^[%s\n\r]*$") then
        _continue_0 = true
        break
      end
      if i == #str_lines and line:match("^[%s\n\r]*$") then
        break
      end
      line = line:gsub("^" .. tostring(indent), '')
      new_str = new_str .. (line .. "\n")
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return new_str
end
local replace_lines
replace_lines = function(file_path, repl, want, conf)
  need_type(file_path, 'string', 1)
  need_type(repl, 'string', 2)
  need_type(want, 'string', 3)
  assert(path.isfile(file_path))
  if conf then
    need_type(conf, 'table', 4)
  end
  local replaced = 0
  local new_file = ''
  for _, line in ipairs(strx.splitlines(file.read(file_path))) do
    local _continue_0 = false
    repeat
      if not (conf and conf.limit <= replaced) then
        if line:match(repl) then
          new_file = new_file .. "\n" .. tostring(want)
          replaced = replaced + 1
          _continue_0 = true
          break
        end
      end
      new_file = new_file .. "\n" .. tostring(line)
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  if replaced > 0 then
    assert(file.write(file_path, new_file))
    return emit(tostring(file_path) .. ": Replaced " .. tostring(replaced) .. " line" .. tostring(replaced > 1 and 's' or ''))
  end
end
return {
  trim = trim,
  for_os = for_os,
  need_one = need_one,
  coalesce = coalesce,
  need_type = need_type,
  is_symlink = is_symlink,
  valid_input = valid_input,
  make_symlink = make_symlink,
  depath = depath,
  repath = repath,
  replace_lines = replace_lines,
  ensure_path_exists = ensure_path_exists
}
