path = require"pl.path"
file = require"pl.file"
strx = require"pl.stringx"

import StateObject from require"moondot.obj.stateobject"
import sandbox_export from require"moondot.env"
import depath, repath, ensure_path_exists from require"moondot.utils"
import var from require"moondot.obj.config"
import executeex from require"pl.utils"
import need_type from require"moondot.assertions"
import emit from require"moondot.output"

-- TODO: Design env such that items like env.git.#{command} will automatically run inside
--       of the repositories repo path

class Repo extends StateObject
  clone = (url, rpath) ->
    ok, _, out, err = executeex "git clone #{url} #{rpath}"
    unless ok
      err = "#{out}\n#{err}" if out != ''

    return ok, err

  git = setmetatable {}, __index: (_, cmd) -> (rpath, ...) ->
    need_type cmd, 'string', 1
    need_type rpath, 'string', 2

    ensure_path_exists rpath

    exec_str = "cd #{rpath} && git #{cmd}"
    for a in *({...})
      exec_str ..= " #{a}"

    ok, _, out, err = executeex exec_str
    unless ok
      err = "#{out}\n#{err}" if out != ''

    return ok, err, out

  is_repo = (rpath) ->
    return false unless path.isdir rpath
    return false unless git['rev-parse'] rpath, "--is-inside-work-tree"
    return true

  new: (name, state_tbl={}) =>
    need_type name, 'string', 1
    need_type state_tbl, 'table', 2

    @name = name

    if state_tbl.git
      need_type state_tbl.git, 'string', 'state_tbl.git'

      @git = state_tbl.git
    else
      @git = "github.com"

    @ensure   = 'present'
    @path     = "#{var.cache_dir}/repos/#{depath name}"
    @prefix   = "#{var.cache_dir}/roots/#{depath name}"
    @metadata = "#{var.cache_dir}/.metadata/#{depath name}"
    super!

  check: =>
    chk = ->
      return false, "Not a valid repository" unless is_repo @path
      return false, "Can't create #{@metadata}" unless ensure_path_exists @metadata
      return false, "Missing commit metadata" unless path.isfile "#{@metadata}/commit"
      return false, "Missing branch metadata" unless path.isfile "#{@metadata}/branch"

      if @installer
        return false, "Could not generate prefix" unless ensure_path_exists @prefix

      ok, err = git.fetch @path
      unless ok
        @error "git: #{err}"
        return false, "Failed to git-fetch"

      ok, err = git.pull @path
      unless ok
        @error "git: #{err}"
        return false, "Failed to git-pull"

      ok, err, commit = git['rev-parse'] @path, 'head'
      unless ok
        @error "git: #{err}"
        return false, "Failed to get latest commit"
      commit = strx.strip commit, ' \n\r'

      ok, err, branch = git['rev-parse'] @path, '--abbrev-ref', 'HEAD'
      unless ok
        @error "git: #{err}"
        return false, "Failed to get branch"
      branch = strx.strip branch, ' \n\r'

      current_branch = file.read "#{@metadata}/branch"
      current_commit = file.read "#{@metadata}/commit"

      if current_branch != branch
        return false, "Branch has changed"

      if current_commit != commit
        return false, "Latest commit has changed"

      return true

    @state, reason = chk!
    return @state, reason

  enforce: =>
    return false unless ensure_path_exists "#{var.cache_dir}/repos/"
    return false unless ensure_path_exists "#{var.cache_dir}/roots/"
    return false unless ensure_path_exists @metadata
    return false unless ensure_path_exists @path

    switch @ensure
      when 'present'
        unless is_repo @path
          emit "git-clone #{@}"
          ok, err = git.clone @path, "https://#{@git}/#{@name}", "."
          unless ok
            @error "git: #{err}"
            return false

        if @checkout and @checkout != ''
          emit "git-checkout #{@}"
          ok, err = git.checkout @path, @branch
          unless ok
            @error "git: #{err}"
            return false

        ok, err, branch = git['rev-parse'] @path, '--abbrev-ref', 'HEAD'
        unless ok
          @error "git: #{err}"
          return false
        branch = strx.strip branch, ' \n\r'

        ok, err, commit = git['rev-parse'] @path, 'head'
        unless ok
          @error "git: #{err}"
          return false
        commit = strx.strip commit, ' \n\r'

        emit "Updated metadata"
        assert file.write("#{@metadata}/commit", commit)
        assert file.write("#{@metadata}/branch", branch)

      when 'absent'
        if path.isdir @path
          ok, err = path.rmdir @path
          unless ok
            @error "Failed to remove #{@path}"
            return false

    return true

sandbox_export { repo: Repo }

{
  :Repo
}