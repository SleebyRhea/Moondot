etlua = require"etlua"
path  = require"pl.path"
file  = require"pl.file"
strx  = require"pl.stringx"
md5   = require"md5"

import
  dump
  from require"pl.pretty"

import
  sandbox_export
  from require"src.env"

import
  getters
  setters
  private
  from require"src.oo_ext"

import
  emit
  add_margin
  from require"src.output"

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
  from require"src.utils"

import
  StateObject
  from require"src.obj.stateobject"

import
  Config
  set
  var
  from require"src.obj.config"

import
  Repo
  from require"src.obj.repo"


-- @todo Replicate the current functionality for in-line templates with margins
-- @todo Use leafos tableshape to make this a much more resilient (and easily extensible) class
--
--
class File extends StateObject
  Config "indentation", '  ', (want) -> want

  --- Trim the margins from a given string. Uses the configured Config[indentation]
  -- @param str String to trim the left margin off of
  -- @param margin Number of instances of Config[indentation] to strip
  trim_margin = (str, margin) ->
    return str if margin < 1

    new_str, str_lines = '', strx.split str, '\n'
    for _, line in ipairs str_lines
      line = line\gsub "^#{var.indentation\rep margin}", ''
      break if i == #str_lines and (line == '' or line\match "^%s+$")
      continue if i == 1 and (line == '' or line\match "^%s+$")
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

    @name = filepath
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

    switch @kind
      when 'source'
        if strx.at(state_tbl.source, 1) == '@'
          repo_name = strx.lstrip(strx.split(state_tbl.source,":")[1], '@')
          unless @repo = Repo.fetch repo_name
            @error "Missing required repo: #{repo_name}"
            return false
          if @repo.ensure != 'present'
            @error "Cannot reference repo marked as #{@repo.ensure}"
          @source_file = "#{@repo.path}/#{@path}"

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
      switch @kind
        when 'directory'
          unless path.isdir @path
            return false
        else
          unless is_symlink @path
            return false

          unless path.link_attrib(@path).target == @source_file
            return false
      return true

    @state = chk!
    if @ensure == 'absent'
      @state = not @state

    return @state

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

    local err
    local tmpl
    switch @kind
      when 'inline'
        tmpl, err = etlua.compile @inline_data
      when 'source'
        tmpl, err = etlua.compile file.read @source_file

    if err
      @error "Failed to render #{@}: #{err}"
      return false

    -- Ensure that no matter what, our source_file is always overridden to be cached
    -- rather than linked to a file directly
    @rendered = tmpl(state_tbl.environment or {})
    @source_file = "#{var.cache_dir}/.compiled/#{depath @path}"

  check: =>
    unless super!
      state = false
      return @state

    unless md5.sum(@rendered) == md5.sum(file.read @path)
      state = false
      return @state

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