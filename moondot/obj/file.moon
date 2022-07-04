etlua = require"etlua"
path  = require"pl.path"
file  = require"pl.file"
strx  = require"pl.stringx"
md5   = require"md5"

import dump from require"pl.pretty"
import executeex from require"pl.utils"
import sandbox_export from require"moondot.env"
import getters, setters, private from require"moondot.oo_ext"
import emit, add_margin from require"moondot.output"
import StateObject from require"moondot.obj.stateobject"
import Config, set, var from require"moondot.obj.config"
import Repo from require"moondot.obj.repo"

import
  depath
  repath
  need_one
  need_type
  is_symlink
  valid_input
  replace_home
  make_symlink
  ensure_path_exists
  from require"moondot.utils"

class File extends StateObject
  Config "indentation", '  ', (want) -> want

  --- Trim the margins from a given string. Uses the configured Config[indentation]
  -- @param str String to trim the left margin off of
  -- @param margin Number of instances of Config[indentation] to strip
  trim_margin = (str, margin) ->
    return str if margin < 1

    new_str, str_lines = '', strx.splitlines str
    for i, line in ipairs str_lines
      continue if i == 1 and line\match "^[%s\n\r]*$"
      break if i == #str_lines and line\match "^[%s\n\r]*$"
      line = line\gsub "^#{var.indentation\rep margin}", ''
      new_str ..= line .. "\n"

    return new_str

  new: (filepath, state_tbl) =>
    need_type filepath, 'string', 1
    need_type state_tbl, 'table', 2

    if state_tbl.ensure
      need_type state_tbl.ensure, 'string', "state_tbl.ensure"
    else
      state_tbl.ensure = 'present'

    state_tbl.ensure, err_var = valid_input state_tbl.ensure, 'invalid', {
      'present'
      'absent'
    }

    @name = path.expanduser filepath
    @path = path.expanduser filepath
    @ensure = state_tbl.ensure

    switch state_tbl.ensure
      when 'invalid'
        @critical_error "Invalid ensure declaration for #{@} (got: #{err_var}}"
      when 'absent'
        @kind = 'absent'
        need_type state_tbl.source, 'nil', 'state_tbl.source'
        need_type state_tbl.inline, 'nil', 'state_tbl.inline'
      else
        @kind = need_one state_tbl, {
          source: state_tbl.source
          inline: state_tbl.inline
          directory: state_tbl.directory
        }

        if state_tbl.chmod
          need_type state_tbl.chmod, 'string', 'state_tbl.chmod'
          unless state_tbl.chmod\match '^[012][0124567][0124567][0124567]$'
            @critical_error "Invalid chmod declardation for #{@} (got: #{state_tbl.chmod})"
          @chmod = state_tbl.chmod

    switch @kind
      when 'source'
        if strx.at(state_tbl.source, 1) == '@'
          repo_name = strx.lstrip(strx.split(state_tbl.source,":")[1], '@')
          repo_path = state_tbl.source\gsub "%@#{repo_name}%:", ''
          unless @repo = Repo.fetch repo_name
            @error "Missing required repo: #{repo_name}"
            return false
          if @repo.ensure != 'present'
            @error "Cannot reference repo marked as #{@repo.ensure}"
            return false
          @source_file = "#{@repo.path}/#{repo_path}"

        else
          @source_file = path.expanduser state_tbl.source

        if @ensure != 'absent'
          need_type @source_file, 'string', "#{@}.source_file"

      when 'inline'
        @inline_data = state_tbl.inline
        @source_file = "#{var.cache_dir}/.compiled/#{depath @path}"

        if state_tbl.margin
          need_type state_tbl.margin, 'number', 'state_tbl.margin'
          @inline_data = trim_margin @inline_data, state_tbl.margin

        if @ensure != 'absent'
          need_type @source_file, 'string', "#{@}.source_file"

    super!

  --- Determine whether or not the File we are configuring on-system is up-to-date
  check: =>
    chk = ->
      if @kind == 'directory'
        return false, 'Path is not a directory' unless path.isdir @path
        return true

      unless is_symlink @path
        return false, 'Path is not a symlink'

      unless path.link_attrib(@path).target == @source_file
        return false, 'Symlink is incorrectly linked'

      if @kind == 'inline'
        contents = file.read @path
        unless contents == @inline_data
          return false, 'Contents do not match cached data'

      return true

    @state, reason = chk!
    if @ensure == 'absent'
      @state = not @state

    return @state, reason

  --- Generate a function to update the File on-system if necessary
  enforce: () => switch @ensure
    when 'present'
      if @kind == 'directory'
        return false unless ensure_path_exists @path
        return true

      return false unless ensure_path_exists "#{var.cache_dir}/.compiled"
      return false unless ensure_path_exists "#{path.dirname @path}"
      return true if @state

      if @repo
        return false unless @repo.state

      if path.isfile @path
        file.delete @path

      if path.isdir @path
        path.rmdir @path

      -- ... cache file, make symlink, etc etc
      if @kind == 'inline'
          ok, err = file.write @source_file, @inline_data
          unless ok
            @error "Failed to write data to #{@source_file}"
            return false

      ok, err = make_symlink @source_file, @path
      unless ok
        @error "Failed to link #{@path} to #{@source_file}"
        return false

      if @chmod
        ok, _, out, err = executeex "chmod #{@chmod} #{@path}"
        unless ok
          @error "Failed to chmod #{@path} to #{@chmod}"
          return false

      return true

    when 'absent'
      -- ... delete cache file, delete symlink, etc etc
      ok, err = file.delete @source_file
      unless ok
        @error "Failed to delete source: #{@source_file}"
        return false

      ok, err = file.delete @path
      unless ok
        @error "Failed to delete path: #{@path}"
        return false

      return true


--- Represents a file being templated and cached
class Template extends File
  new: (filepath, state_tbl) =>
    super filepath, state_tbl

    if state_tbl.environment
      need_type state_tbl.environment, 'table', 'state_tbl.environment'
      @environment = state_tbl.environment
    else
      @environment = {}

    @source_file = "#{var.cache_dir}/.compiled/#{depath @path}"

  check: =>
    local err
    local tmpl

    switch @kind
      when 'inline'
        tmpl, err = etlua.compile @inline_data
        if err
          @error "Failed to render #{@}: #{err}"
          return false
        @inline_data = tmpl @environment

      when 'source'
        tmpl, err = etlua.compile file.read @source_file
        if err
          @error "Failed to render #{@}: #{err}"
          return false
        @rendered = tmpl @environment

    ok, reason = super!
    unless ok
      state = false
      return @state, reason

    unless md5.sum(@rendered) == md5.sum(file.read @path)
      state = false
      return @state, 'Path does not match cached data'

    return true

  enforce: =>
    switch @kind
      when 'source'
        file.write @source_file, @rendered
      when 'inline'
        @inline_data = @rendered

    super!

sandbox_export { file: File, template: Template }

{
  :File
  :Template
}