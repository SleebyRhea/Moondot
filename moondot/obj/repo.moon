path = require"pl.path"
strx = require"pl.stringx"

import StateObject from require"moondot.obj.stateobject"
import sandbox_export from require"moondot.env"
import depath, repath, ensure_path_exists from require"moondot.utils"
import var from require"moondot.obj.config"
import executeex from require"pl.utils"
import need_type from require"moondot.assertions"
import emit from require"moondot.output"

class Repo extends StateObject
  clone = (url, rpath) ->
    ok, _, out, err = executeex "git clone #{url} #{rpath}"
    unless ok
      err = "#{out}\n#{err}" if out != ''

    return ok, err

  git = setmetatable {}, __index: (_, cmd) -> (rpath, ...) ->
    need_type rpath, 'string', 1

    ensure_path_exists rpath

    exec_str = "cd #{rpath} && git #{cmd}"
    for a in *({...})
      exec_str ..= " #{a}"

    repo_name = repath rpath\match ".+/([^/]+)$"
    emit "git-#{cmd} #{repo_name}"

    ok, _, out, err = executeex exec_str
    unless ok
      err = "#{out}\n#{err}" if out != ''

    return ok, err

  new: (name, state_tbl={}) =>
    need_type name, 'string', 1
    need_type state_tbl, 'table', 2

    @name = name

    if state_tbl.git
      need_type state_tbl.git, 'string', 'state_tbl.git'

      @git = state_tbl.git
    else
      @git = "github.com"

    @ensure = 'present'
    @path = "#{var.cache_dir}/repos/#{depath name}"
    super!

  enforce: () =>
    return false unless ensure_path_exists "#{var.cache_dir}/repos/"
    switch @ensure
      when 'present'
        unless path.isdir @path
          ok, err = git.clone @path, "https://#{@git}/#{@name}"
          unless ok
            @error "git: #{err}"
            return false

        ok, err = git.fetch @path
        unless ok
          @error "git: #{err}"
          return false

        ok, err = git.pull @path
        unless ok
          @error "git: #{err}"
          return false

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