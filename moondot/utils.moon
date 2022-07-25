lfs  = require"lfs"
dir  = require"pl.dir"
strx = require"pl.stringx"
path = require"pl.path"
file = require"pl.file"

import emit from require"moondot.output"
import executeex from require"pl.utils"
import need_one, need_type from require"moondot.assertions"


--- Validate the variable provided against a list of valid options, with a fallback
-- @param want The variable to test
-- @param fallback The variable to fallback onto on failure
-- @param tbl Table that contains valid values
-- @return want (when successful), fallback (when unsuccessful)
-- @return want (when unsuccessful), nil (when successful)
valid_input = (want, fallback, tbl) ->
  need_type tbl, 'table', 3

  for _, value in ipairs tbl
    return want, nil if want == value
  return fallback, want


--- Replace path separators in a filepath with @'s to allow for easier cacheing
-- @param path File path to translate
-- @return Translated filepath
-- @see repath
depath = (filepath) ->
  need_type filepath, 'string', 1

  strx.replace filepath, path.sep, "@"


--- Replace @ signs with path separators
-- @param depathed Filepath that has been run through depath
-- @return Translated filepath
-- @see depath
repath = (depathed) ->
  need_type depathed, 'string', 1
  strx.replace depathed, "@", path.sep


--- Coalesce two tables into single table.
-- @param t1 Primary key/val table, keys found in this table override t2
-- @param t2 Secondary key/val table
-- @return table Composite of the two tables
coalesce = (t1, t2) ->
  need_type t1, 'table', 1
  need_type t2, 'table', 2

  res = {}
  for k, v in pairs(t2) do res[k] = v
  for k, v in pairs(t1) do res[k] = v

  return res


local for_os
local current_os_type
do
  ok, _, current_os_type, err = executeex"uname"
  assert ok, "Failed to execute uname to determine operating system: #{err}"

  current_os_type = current_os_type\gsub '[\r\n]', ''
  current_os_type = string.lower current_os_type

  --- Run a function when the current operating system matches the given os
  -- @param os string Operating system type to run the function on
  -- @param fn funciton Function to run
  -- @param ... Variables to pass to the function
  -- @return Returns from function fn, or false
  for_os = (os, fn, ...) ->
    need_type os, 'string', 1
    need_type fn, 'function', 2

    switch string.lower os
      when 'macos', 'darwin', 'osx'
        return fn ... if current_os_type == 'darwin'
      when 'linux'
        return fn ... if current_os_type == 'linux'
      when 'bsd'
        return fn ... if current_os_type == 'bsd'

    return false


--- Create a symlink at destination
-- @param target Location to symlink to
-- @param destination Location to create the symlink
-- @return Success boolean
-- @return nil (returned error string on failure)
make_symlink = (target, destination) ->
  need_type target, 'string', 1
  need_type destination, 'string', 2

  switch current_os_type
    when 'darwin', 'linux', 'bsd'
      emit "Linking #{destination} -> #{target}"
      ok, code, out, err = executeex "ln -sf #{target} #{destination}"
      error "make_symlink: ln returned code #{code}:\n#{out}\n#{err}\n" unless ok
      return true

    else
      return false, "Symlinking is unsupported on #{current_os_type} at this time"

  return false, "Unexpected execution path (reached end of make_symlink)"


--- Check if a given filepath is actually a symlink
-- @param fpath Filepath string
-- @return true if filepath is a symlink, false if it is not
-- @see http://lua-users.org/lists/lua-l/2012-04/msg01106.html
is_symlink = (fpath) ->
  need_type fpath, 'string', 1

  attr = lfs.attributes fpath
  link = lfs.symlinkattributes fpath

  return true if link and link.target
  return false unless attr or link
  return (attr.dev ~= link.dev or attr.ino ~= link.ino)


--- Ensure that a directory exists
-- @param fpath Directory filepath to check (and potentially makepath for)
-- @return true if it exists or was created, false if not
-- @return nil on success, error string on failure
ensure_path_exists = (fpath) ->
  if not path.exists fpath
    ok, err = dir.makepath fpath
    return nil, err unless ok
  return true


--- Trim the margins from a given string. Uses the configured Config[indentation]
-- @param str String to trim the left margin off of
-- @param margin Number of instances of Config[indentation] to strip
trim = (indent, str) ->
  new_str, str_lines = '', strx.splitlines str
  for i, line in ipairs str_lines
    continue if i == 1 and line\match "^[%s\n\r]*$"
    break if i == #str_lines and line\match "^[%s\n\r]*$"
    line = line\gsub "^#{indent}", ''
    new_str ..= line .. "\n"

  return new_str

replace_lines = (file_path, repl, want, conf) ->
  need_type file_path, 'string', 1
  need_type repl, 'string', 2
  need_type want, 'string', 3

  assert path.isfile file_path

  if conf then need_type conf, 'table', 4

  replaced = 0
  new_file = ''

  for _, line in ipairs strx.splitlines file.read file_path
    unless conf and conf.limit <= replaced
      if line\match repl
        new_file ..= "\n#{want}"
        replaced += 1
        continue
    new_file ..= "\n#{line}"

  if replaced > 0
    assert file.write(file_path, new_file)
    emit "#{file_path}: Replaced #{replaced} line#{replaced > 1 and 's' or ''}"

chomp = (str) ->
  need_type str, 'string', 1

  str = str\gsub "^[%S+\n\r]", ''
  str = str\gsub "[%S+\n\r]$", ''
  return str

{
  :trim
  :chomp
  :for_os
  :need_one
  :coalesce
  :need_type
  :is_symlink
  :valid_input
  :make_symlink
  :depath
  :repath
  :replace_lines
  :ensure_path_exists
}