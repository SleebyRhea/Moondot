local path = require("pl.path")
local need_type
need_type = require("moondot.assertions").need_type
local sandbox_export
sandbox_export = require("moondot.env").sandbox_export
local valid_input
valid_input = require("moondot.utils").valid_input
local emit, insert_margin, run_with_margin
do
  local _obj_0 = require("moondot.output")
  emit, insert_margin, run_with_margin = _obj_0.emit, _obj_0.insert_margin, _obj_0.run_with_margin
end
local executeex
executeex = require("pl.utils").executeex
local var, set, Config
do
  local _obj_0 = require("moondot.obj.config")
  var, set, Config = _obj_0.var, _obj_0.set, _obj_0.Config
end
local StateObject
StateObject = require("moondot.obj.stateobject").StateObject
local Rock
do
  local _class_0
  local luarocks
  local _parent_0 = StateObject
  local _base_0 = {
    check = function(self)
      local chk
      chk = function()
        if not (var.luarocks and var.luarocks ~= 'none') then
          return false, "Luarocks variable unset"
        end
        local ok, code, out, err = luarocks.show(self.name)
        if not (ok) then
          local _exp_0 = code
          if 1 == _exp_0 then
            return false, "Rock " .. tostring(self.name) .. " is not installed"
          else
            return false, insert_margin("Luarocks encountered an error attempting to run: \n" .. tostring(out) .. "\n" .. tostring(err))
          end
        end
        return true, 'Rock is currently installed'
      end
      local reason
      self.state, reason = chk()
      if self.ensure == 'absent' then
        self.state = not self.state
        return false, reason
      end
      return self.state, reason
    end,
    enforce = function(self)
      if not (var.luarocks and var.luarocks ~= 'none') then
        return false, "Luarocks variable unset"
      end
      local _exp_0 = self.ensure
      if 'present' == _exp_0 then
        emit("luarocks-install " .. tostring(self.name))
        return run_with_margin(function()
          local ok, code, out, err = luarocks.install(self.name)
          if not (ok) then
            self:error("luarocks: " .. tostring(code) .. ":\n" .. tostring(insert_margin(out)) .. "\n" .. tostring(insert_margin(err)))
          end
          emit(out)
          return true
        end)
      elseif 'absent' == _exp_0 then
        emit("luarocks-remove " .. tostring(self.name))
        return run_with_margin(function()
          local ok, code, out, err = luarocks.remove(self.name)
          if not (ok) then
            self:error("luarocks: " .. tostring(code) .. ":\n" .. tostring(insert_margin(out)) .. "\n" .. tostring(insert_margin(err)))
            return false
          end
          emit(out)
          return true
        end)
      else
        return false
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, name, state_tbl)
      need_type(name, 'string', 1)
      if state_tbl then
        need_type(state_tbl, 'table', 2)
        local err_var
        state_tbl.ensure, err_var = valid_input(state_tbl.ensure, 'invalid', {
          'present',
          'absent'
        })
        self.ensure = state_tbl.ensure
      else
        self.ensure = 'present'
      end
      self.name = name
      return _class_0.__parent.__init(self)
    end,
    __base = _base_0,
    __name = "Rock",
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
  Config('luarocks', 'none', function(want, current)
    if not (want ~= nil) then
      return nil
    end
    if not (type(want) == 'string') then
      return current
    end
    local dehomed = path.expanduser(want)
    if not (path.isfile(want)) then
      return current
    end
    return dehomed
  end)
  luarocks = setmetatable({ }, {
    __index = function(_, cmd)
      return function(...)
        need_type(cmd, 'string', 1)
        if not (var.luarocks and path.isfile(var.luarocks)) then
          return false, 'missing luarocks installation'
        end
        local arg_str = ''
        local _list_0 = ({
          ...
        })
        for _index_0 = 1, #_list_0 do
          local a = _list_0[_index_0]
          arg_str = arg_str .. tostring(a) .. " "
        end
        local exec_str = "env LUA_PATH= LUA_CPATH= " .. tostring(var.luarocks) .. " " .. tostring(cmd) .. " " .. tostring(arg_str)
        local ok, code, out, err = executeex(exec_str)
        out = insert_margin("\n" .. tostring(out))
        err = insert_margin("\n" .. tostring(err))
        if not (ok) then
          if out ~= '' then
            err = tostring(out) .. "\n" .. tostring(err)
          end
        end
        return ok, code, out, err
      end
    end
  })
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Rock = _class_0
end
sandbox_export({
  rock = Rock
})
return {
  Rock = Rock
}
