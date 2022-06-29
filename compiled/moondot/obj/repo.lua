local path = require("pl.path")
local StateObject
StateObject = require("moondot.obj.stateobject").StateObject
local sandbox_export
sandbox_export = require("moondot.env").sandbox_export
local depath, ensure_path_exists
do
  local _obj_0 = require("moondot.utils")
  depath, ensure_path_exists = _obj_0.depath, _obj_0.ensure_path_exists
end
local var
var = require("moondot.obj.config").var
local executeex
executeex = require("pl.utils").executeex
local need_type
need_type = require("moondot.assertions").need_type
local emit
emit = require("moondot.output").emit
local Repo
do
  local _class_0
  local clone, fetch, pull
  local _parent_0 = StateObject
  local _base_0 = {
    enforce = function(self)
      if not (ensure_path_exists(tostring(var.cache_dir) .. "/repos/")) then
        return false
      end
      local _exp_0 = self.ensure
      if 'present' == _exp_0 then
        if not (path.isdir(self.path)) then
          emit("git-clone " .. tostring(self.name))
          local ok, err = clone("https://" .. tostring(self.git) .. "/" .. tostring(self.name), self.path)
          if not (ok) then
            self:error("git: " .. tostring(err))
            return false
          end
        end
        emit("git-fetch " .. tostring(self.name))
        local ok, err = fetch(self.path)
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false
        end
        emit("git-pull " .. tostring(self.name))
        ok, err = pull(tostring(self.path))
        if not (ok) then
          self:error("git: " .. tostring(err))
          return false
        end
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
      self.ensure = 'present'
      self.path = tostring(var.cache_dir) .. "/repos/" .. tostring(depath(name))
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
  clone = function(url, rpath)
    local ok, _, out, err = executeex("git clone " .. tostring(url) .. " " .. tostring(rpath))
    if not (ok) then
      if out ~= '' then
        err = tostring(out) .. "\n" .. tostring(err)
      end
    end
    return ok, err
  end
  fetch = function(rpath)
    local ok, _, out, err = executeex("cd " .. tostring(rpath) .. " && git fetch")
    if not (ok) then
      if out ~= '' then
        err = tostring(out) .. "\n" .. tostring(err)
      end
    end
    return ok, err
  end
  pull = function(rpath)
    local ok, _, out, err = executeex("cd " .. tostring(rpath) .. " && git pull")
    if not (ok) then
      if out ~= '' then
        err = tostring(out) .. "\n" .. tostring(err)
      end
    end
    return ok, err
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
