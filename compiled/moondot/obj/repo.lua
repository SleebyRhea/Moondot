local path = require("pl.path")
local file = require("pl.file")
local strx = require("pl.stringx")
local StateObject
StateObject = require("moondot.obj.stateobject").StateObject
local sandbox_export
sandbox_export = require("moondot.env").sandbox_export
local var
var = require("moondot.obj.config").var
local executeex
executeex = require("pl.utils").executeex
local need_type
need_type = require("moondot.assertions").need_type
local emit, run_with_margin, insert_margin
do
  local _obj_0 = require("moondot.output")
  emit, run_with_margin, insert_margin = _obj_0.emit, _obj_0.run_with_margin, _obj_0.insert_margin
end
local trim, for_os, depath, repath, need_one, is_symlink, valid_input, replace_home, make_symlink, ensure_path_exists
do
  local _obj_0 = require("moondot.utils")
  trim, for_os, depath, repath, need_one, need_type, is_symlink, valid_input, replace_home, make_symlink, ensure_path_exists = _obj_0.trim, _obj_0.for_os, _obj_0.depath, _obj_0.repath, _obj_0.need_one, _obj_0.need_type, _obj_0.is_symlink, _obj_0.valid_input, _obj_0.replace_home, _obj_0.make_symlink, _obj_0.ensure_path_exists
end
local Repo
do
  local _class_0
  local contexts, git, is_repo, set_context
  local _parent_0 = StateObject
  local _base_0 = {
    check = function(self)
      local chk
      chk = function()
        self.needs_build = true
        if not (is_repo(self.path)) then
          return false, "Repo filepath is not a valid repository"
        end
        if not (ensure_path_exists(self.metadata)) then
          return false, "Can't create " .. tostring(self.metadata)
        end
        if not (path.isfile(tostring(self.metadata) .. "/commit")) then
          return false, "Missing commit metadata"
        end
        if not (path.isfile(tostring(self.metadata) .. "/branch")) then
          return false, "Missing branch metadata"
        end
        if self.builder then
          if not (ensure_path_exists(self.prefix)) then
            return false, "Could not generate prefix"
          end
        end
        self.needs_build = false
        local ok, err = git.fetch(self.path)
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false, "Failed to git-fetch"
        end
        ok, err = git.pull(self.path)
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false, "Failed to git-pull"
        end
        local commit
        ok, err, commit = git['rev-parse'](self.path, 'HEAD')
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false, "Failed to get latest commit"
        end
        commit = strx.strip(commit, ' \t\n\r')
        local branch
        ok, err, branch = git['rev-parse'](self.path, '--abbrev-ref', 'HEAD')
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false, "Failed to get branch"
        end
        branch = strx.strip(branch, ' \t\n\r')
        local current_branch = file.read(tostring(self.metadata) .. "/branch")
        local current_commit = file.read(tostring(self.metadata) .. "/commit")
        if current_branch ~= branch then
          self.needs_build = true
          return false, "Branch has changed"
        end
        if current_commit ~= commit then
          self.needs_build = true
          return false, "Latest commit has changed"
        end
        if self.install_files then
          for target, link in pairs(self.install_files) do
            if not (is_symlink(link)) then
              return false, "Missing required symlink"
            end
            if not (path.link_attrib(link).target == target) then
              return false, "Invalid symlink found"
            end
          end
        end
        if self.creates_files then
          local _list_0 = self.creates_files
          for _index_0 = 1, #_list_0 do
            local f = _list_0[_index_0]
            if not (path.isfile(f) or path.isdir(f)) then
              self.needs_build = true
              return false, "Missing required build result"
            end
          end
        end
        return true
      end
      local reason
      self.state, reason = chk()
      return self.state, reason
    end,
    enforce = function(self)
      if not (ensure_path_exists(tostring(var.cache_dir) .. "/repos/")) then
        return false
      end
      if not (ensure_path_exists(tostring(var.cache_dir) .. "/roots/")) then
        return false
      end
      if not (ensure_path_exists(self.metadata)) then
        return false
      end
      if not (ensure_path_exists(self.path)) then
        return false
      end
      local _exp_0 = self.ensure
      if 'present' == _exp_0 then
        local needs_build = self.needs_build
        if not (is_repo(self.path)) then
          needs_build = true
          emit("git-clone " .. tostring(self.name))
          local ok, err = git.clone(self.path, "https://" .. tostring(self.git) .. "/" .. tostring(self.name), ".")
          if not (ok) then
            self:error("git: " .. tostring(err))
            return false
          end
        end
        if self.checkout and self.checkout ~= '' then
          emit("git-checkout " .. tostring(self.name))
          local ok, err = git.checkout(self.path, self.branch)
          if not (ok) then
            self:error("git: " .. tostring(err))
            return false
          end
        end
        local ok, err, branch = git['rev-parse'](self.path, '--abbrev-ref', 'HEAD')
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false
        end
        branch = strx.strip(branch, ' \t\n\r')
        local commit
        ok, err, commit = git['rev-parse'](self.path, 'HEAD')
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false
        end
        commit = strx.strip(commit, ' \t\n\r')
        assert(file.write(tostring(self.metadata) .. "/commit", commit))
        assert(file.write(tostring(self.metadata) .. "/branch", branch))
        if self.builder and needs_build then
          self:cleaner()
          self:builder()
          local _list_0 = self.creates_files
          for _index_0 = 1, #_list_0 do
            local f = _list_0[_index_0]
            if not (path.isfile(f) or path.isdir(f)) then
              self:error("Failed to build " .. tostring(f))
              return false
            end
          end
        end
        if self.install_files then
          for target, link in pairs(self.install_files) do
            if path.isfile(link) then
              file.delete(link)
            end
            if path.isdir(link) then
              path.rmdir(link)
            end
            ok, err = make_symlink(target, link)
            if not (ok) then
              self:error("Failed to link " .. tostring(link) .. " to " .. tostring(target))
              return false
            end
          end
        end
        return true
      elseif 'absent' == _exp_0 then
        if path.isdir(self.path) then
          local ok, err = path.rmdir(self.path)
          if not (ok) then
            self:error("Failed to remove " .. tostring(self.path))
            return false
          end
        end
      end
      return true
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, name, state_tbl)
      if state_tbl == nil then
        state_tbl = { }
      end
      need_type(name, 'string', 1)
      need_type(state_tbl, 'table', 2)
      self.name = name
      if state_tbl.git then
        need_type(state_tbl.git, 'string', 'state_tbl.git')
        self.git = state_tbl.git
      else
        self.git = "github.com"
      end
      self.safe_name = name:gsub('/', '+')
      self.ensure = 'present'
      self.path = tostring(var.cache_dir) .. "/repos/" .. tostring(self.safe_name)
      self.prefix = tostring(var.cache_dir) .. "/roots/" .. tostring(self.safe_name)
      self.metadata = tostring(var.cache_dir) .. "/.metadata/" .. tostring(self.safe_name)
      if state_tbl.builder then
        need_type(state_tbl.builder, 'function', 'state_tbl.builder')
        need_type(state_tbl.cleaner, 'function', 'state_tbl.cleaner')
        need_type(state_tbl.creates, 'table', 'state_tbl.creates')
        contexts[self] = {
          coalesce = coalesce,
          tostring = tostring,
          string = string,
          ipairs = ipairs,
          pairs = pairs,
          table = table,
          emit = emit,
          var = var,
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
          vars = { },
          env = {
            prefix = self.prefix,
            del_var = function(key)
              contexts[self].vars[key] = ''
            end,
            set_var = function(key, val)
              contexts[self].vars[key] = val
            end,
            git = setmetatable({ }, {
              __index = function(_, cmd)
                return function(...)
                  emit("git-" .. tostring(cmd) .. " " .. tostring(self.name))
                  return assert(git[cmd](self.path, ...))
                end
              end
            }),
            run = function(cmd, ...)
              local set_env = false
              local command_str = cmd
              local _list_0 = ({
                ...
              })
              for _index_0 = 1, #_list_0 do
                local a = _list_0[_index_0]
                command_str = command_str .. " '" .. tostring(a) .. "'"
              end
              emit("Running " .. tostring(command_str) .. " ...")
              for key, val in pairs(contexts[self].vars) do
                set_env = true
                command_str = tostring(key) .. "=" .. tostring(val) .. " " .. tostring(command_str)
              end
              if set_env then
                command_str = "env " .. tostring(command_str)
              end
              command_str = "cd " .. tostring(self.path) .. " && " .. tostring(command_str)
              local ok, _, out, err = executeex(command_str)
              assert(ok, tostring(cmd) .. ": " .. tostring(out) .. " (err:" .. tostring(err) .. ")")
              out = insert_margin(out)
              return print(trim('', out))
            end,
            file = {
              replace_lines = function(_file, repl, want, conf)
                need_type(_file, 'string', 1)
                need_type(repl, 'string', 2)
                need_type(want, 'string', 3)
                local file_path = self.path .. "/" .. _file
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
                  return emit(tostring(_file) .. ": Replaced " .. tostring(replaced) .. " line" .. tostring(replaced > 1 and 's' or ''))
                end
              end
            }
          }
        }
        if state_tbl.environment then
          need_type(state_tbl.environment, 'table', state_tbl.environment)
          for k, v in pairs(state_tbl.environment) do
            contexts[self].env[k] = v
          end
        end
        self.builder = function()
          emit("Running builder ...")
          return run_with_margin(function()
            local ok, err = pcall(function()
              return set_context(self, state_tbl.builder)
            end)
            if not (ok) then
              err = insert_margin(err)
              self:error(trim('', err))
              self.state = false
            end
          end)
        end
        self.cleaner = function()
          emit("Cleaning repository ...")
          return run_with_margin(function()
            local ok, err = pcall(function()
              return set_context(self, state_tbl.cleaner)
            end)
            if not (ok) then
              self:error(insert_margin(err))
              self.state = false
            end
          end)
        end
        self.creates_files = { }
        for i, f in ipairs(state_tbl.creates) do
          need_type(f, 'string', "state_tbl.creates[" .. tostring(i) .. "]")
          f = string.gsub(f, '^%#prefix:(.*)$', tostring(self.prefix) .. "/%1")
          f = string.gsub(f, '^%#repo:(.*)$', tostring(self.path) .. "/%1")
          table.insert(self.creates_files, f)
        end
      end
      if state_tbl.install then
        need_type(state_tbl.install, 'table', 'state_tbl.install')
        self.install_files = { }
        for target, link in pairs(state_tbl.install) do
          need_type(target, 'string', "state_tbl.install[" .. tostring(target) .. "] (key)")
          need_type(state_tbl.install[target], 'string', "state_tbl.install[" .. tostring(target) .. "] (value)")
          target = string.gsub(target, '^%#prefix:(.*)$', tostring(self.prefix) .. "/%1")
          target = string.gsub(target, '^%#repo:(.*)$', tostring(self.path) .. "/%1")
          self.install_files[target] = link
        end
      end
      return _class_0.__parent.__init(self)
    end,
    __base = _base_0,
    __name = "Repo",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  contexts = { }
  git = setmetatable({ }, {
    __index = function(_, cmd)
      return function(rpath, ...)
        need_type(cmd, 'string', 1)
        need_type(rpath, 'string', 2)
        ensure_path_exists(rpath)
        local exec_str = "git -C '" .. tostring(rpath) .. "' " .. tostring(cmd)
        local _list_0 = ({
          ...
        })
        for _index_0 = 1, #_list_0 do
          local a = _list_0[_index_0]
          exec_str = exec_str .. " " .. tostring(a)
        end
        local ok, out, err
        ok, _, out, err = executeex(exec_str)
        if not (ok) then
          if out ~= '' then
            err = tostring(out) .. "\n" .. tostring(err)
          end
        end
        return ok, err, out
      end
    end
  })
  is_repo = function(rpath)
    if not (path.isdir(rpath)) then
      return false
    end
    if not (git['rev-parse'](rpath, "--is-inside-work-tree")) then
      return false
    end
    return true
  end
  local _exp_0 = string.lower(_VERSION)
  if "lua 5.1" == _exp_0 then
    set_context = function(self, fn)
      need_type(fn, 'function', 1)
      local old_env = _G
      local _G = contexts[self]
      setfenv(fn, contexts[self])
      local ret = {
        fn()
      }
      _G = old_env
      return unpack(ret)
    end
  else
    local _ENV = contexts[self]
    set_context = function(fn)
      return fn()
    end
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Repo = _class_0
end
sandbox_export({
  repo = Repo
})
return {
  Repo = Repo
}
