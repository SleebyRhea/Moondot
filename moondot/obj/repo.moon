path = require"pl.path"
file = require"pl.file"
strx = require"pl.stringx"

import StateObject from require"moondot.obj.stateobject"
import sandbox_export from require"moondot.env"
import var from require"moondot.obj.config"
import executeex from require"pl.utils"
import need_type from require"moondot.assertions"
import emit, run_with_margin, insert_margin from require"moondot.output"

import
  trim
  for_os
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


--- Remote git repository
class Repo extends StateObject
  contexts = {}

  git = setmetatable {}, __index: (_, cmd) -> (rpath, ...) ->
    need_type cmd, 'string', 1
    need_type rpath, 'string', 2

    ensure_path_exists rpath
    for a in *({...})
      exec_str ..= " #{a}"

	emit "Running: #{exec_str}"
    ok, _, out, err = executeex exec_str
    unless ok
      err = "#{out}\n#{err}" if out != ''

    return ok, err, out

  is_repo = (rpath) ->
    return false unless path.isdir rpath
    return false unless git['rev-parse'] rpath, "--is-inside-work-tree"
    return true

  set_context = switch string.lower _VERSION
    when "lua 5.1"
      (fn) =>
        need_type fn, 'function', 1
        old_env = _G
        _G = contexts[@]
        setfenv fn, contexts[@]
        ret = {fn!}
        _G = old_env
        return unpack ret
    else
      _ENV = contexts[@]
      (fn) -> fn!

  --- Track new Git repo
  -- @tparam string Name of the git repo
  -- @tparam table? Local repo configuration
  new: (name, state_tbl={}) =>
    need_type name, 'string', 1
    need_type state_tbl, 'table', 2

    @name = name

    if state_tbl.git
      need_type state_tbl.git, 'string', 'state_tbl.git'

      @git = state_tbl.git
    else
      @git = "github.com"

    @safe_name = name\gsub '/', '+'
    @ensure   = 'present'
    @path     = "#{var.cache_dir}/repos/#{@safe_name}"
    @prefix   = "#{var.cache_dir}/roots/#{@safe_name}"
    @metadata = "#{var.cache_dir}/.metadata/#{@safe_name}"

    if state_tbl.builder
      need_type state_tbl.builder, 'function', 'state_tbl.builder'
      need_type state_tbl.cleaner, 'function', 'state_tbl.cleaner'
      need_type state_tbl.creates, 'table', 'state_tbl.creates'

      contexts[@] = {
        :coalesce
        :tostring
        :string
        :ipairs
        :pairs
        :table
        :emit
        :var
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
        vars: {}
        env: {
          prefix: @prefix
          del_var: (key) ->
            contexts[@].vars[key] = ''
          set_var: (key, val) ->
            contexts[@].vars[key] = val
          git: setmetatable {}, __index: (_, cmd) -> (...) ->
            emit "git-#{cmd} #{@name}"
            assert git[cmd] @path, ...
          run: (cmd, ...) ->
            set_env = false
            command_str = cmd
            for a in *({...})
              command_str ..= " '#{a}'"
            emit "Running #{command_str\sub(1, 30)} ..."
            for key, val in pairs contexts[@].vars
              set_env = true
              command_str = "#{key}=#{val} #{command_str}"
            if set_env
              command_str = "env #{command_str}"

            command_str = "cd #{@path} && #{command_str}"
            ok, _, out, err = executeex command_str
            assert ok, "#{cmd}: #{out} (err:#{err})"
            out = insert_margin out
            print trim '', out
          file: {
            replace_lines: (_file, repl, want, conf) ->
              need_type _file, 'string', 1
              need_type repl, 'string', 2
              need_type want, 'string', 3

              file_path = @path .. "/" .. _file
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
                emit "#{_file}: Replaced #{replaced} line#{replaced > 1 and 's' or ''}"
          }
        }
      }

      if state_tbl.environment
        need_type state_tbl.environment, 'table', state_tbl.environment

        for k, v in pairs state_tbl.environment
          contexts[@].env[k] = v

      @builder = ->
        emit "Running builder ..."
        run_with_margin ->
          ok, err = pcall -> set_context @, state_tbl.builder
          unless ok
            err = insert_margin err
            @error trim '', err
            @state = false

      @cleaner = ->
        emit "Cleaning repository ..."
        run_with_margin ->
          ok, err = pcall -> set_context @, state_tbl.cleaner
          unless ok
            @error insert_margin err
            @state = false

      @creates_files = {}
      for i, f in ipairs state_tbl.creates
        need_type f, 'string', "state_tbl.creates[#{i}]"

        f = string.gsub f, '^%#prefix:(.*)$', "#{@prefix}/%1"
        f = string.gsub f, '^%#repo:(.*)$', "#{@path}/%1"
        table.insert @creates_files, f

    if state_tbl.install
      need_type state_tbl.install, 'table', 'state_tbl.install'

      @install_files = {}
      for target, link in pairs state_tbl.install
        need_type target, 'string', "state_tbl.install[#{target}] (key)"
        need_type state_tbl.install[target], 'string', "state_tbl.install[#{target}] (value)"

        target = string.gsub target, '^%#prefix:(.*)$', "#{@prefix}/%1"
        target = string.gsub target, '^%#repo:(.*)$', "#{@path}/%1"
        @install_files[target] = link

    super!

  check: =>
    chk = ->
      @needs_build = true

      return false, "Repo filepath is not a valid repository" unless is_repo @path
      return false, "Can't create #{@metadata}" unless ensure_path_exists @metadata
      return false, "Missing commit metadata" unless path.isfile "#{@metadata}/commit"
      return false, "Missing branch metadata" unless path.isfile "#{@metadata}/branch"

      if @builder
        return false, "Could not generate prefix" unless ensure_path_exists @prefix

      @needs_build = false

      ok, err = git.fetch @path
      unless ok
        @error "git: #{err}"
        return false, "Failed to git-fetch"

      ok, err = git.pull @path
      unless ok
        @error "git: #{err}"
        return false, "Failed to git-pull"

      ok, err, commit = git['rev-parse'] @path, 'HEAD'
      unless ok
        @error "git: #{err}"
        return false, "Failed to get latest commit"
      commit = strx.strip commit, ' \t\n\r'

      ok, err, branch = git['rev-parse'] @path, '--abbrev-ref', 'HEAD'
      unless ok
        @error "git: #{err}"
        return false, "Failed to get branch"
      branch = strx.strip branch, ' \t\n\r'

      current_branch = file.read "#{@metadata}/branch"
      current_commit = file.read "#{@metadata}/commit"

      if current_branch != branch
        @needs_build = true
        return false, "Branch has changed"

      if current_commit != commit
        @needs_build = true
        return false, "Latest commit has changed"

      if @install_files
        for target, link in pairs @install_files
          unless is_symlink link
            return false, "Missing required symlink"

          unless path.link_attrib(link).target == target
            return false, "Invalid symlink found"

      if @creates_files
        for f in *@creates_files
          unless path.isfile(f) or path.isdir(f)
            @needs_build = true
            return false, "Missing required build result"

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
        needs_build = @needs_build
        unless is_repo @path
          needs_build = true
          emit "git-clone #{@name}"
          ok, err = git.clone @path, "https://#{@git}/#{@name}", "."
          unless ok
            @error "git: #{err}"
            return false

        if @checkout and @checkout != ''
          emit "git-checkout #{@name}"
          ok, err = git.checkout @path, @branch
          unless ok
            @error "git: #{err}"
            return false

        ok, err, branch = git['rev-parse'] @path, '--abbrev-ref', 'HEAD'
        unless ok
          @error "git: #{err}"
          return false
        branch = strx.strip branch, ' \t\n\r'

        ok, err, commit = git['rev-parse'] @path, 'HEAD'
        unless ok
          @error "git: #{err}"
          return false
        commit = strx.strip commit, ' \t\n\r'

        assert file.write("#{@metadata}/commit", commit)
        assert file.write("#{@metadata}/branch", branch)

        if @builder and needs_build
          @cleaner!
          @builder!

          for f in *@creates_files
            unless path.isfile(f) or path.isdir(f)
              @error "Failed to build #{f}"
              return false

        if @install_files
          for target, link in pairs @install_files
            if path.isfile link
              file.delete link

            if path.isdir link
              path.rmdir link

            ok, err = make_symlink target, link
            unless ok
              @error "Failed to link #{link} to #{target}"
              return false

        return true

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
