local etlua = require("etlua")
local path = require("pl.path")
local file = require("pl.file")
local strx = require("pl.stringx")
local md5 = require("md5")
local dump
dump = require("pl.pretty").dump
local sandbox_export
sandbox_export = require("moondot.env").sandbox_export
local getters, setters, private
do
  local _obj_0 = require("moondot.oo_ext")
  getters, setters, private = _obj_0.getters, _obj_0.setters, _obj_0.private
end
local emit, add_margin
do
  local _obj_0 = require("moondot.output")
  emit, add_margin = _obj_0.emit, _obj_0.add_margin
end
local StateObject
StateObject = require("moondot.obj.stateobject").StateObject
local Config, set, var
do
  local _obj_0 = require("moondot.obj.config")
  Config, set, var = _obj_0.Config, _obj_0.set, _obj_0.var
end
local Repo
Repo = require("moondot.obj.repo").Repo
local depath, repath, need_one, need_type, is_symlink, valid_input, replace_home, make_symlink, ensure_path_exists
do
  local _obj_0 = require("moondot.utils")
  depath, repath, need_one, need_type, is_symlink, valid_input, replace_home, make_symlink, ensure_path_exists = _obj_0.depath, _obj_0.repath, _obj_0.need_one, _obj_0.need_type, _obj_0.is_symlink, _obj_0.valid_input, _obj_0.replace_home, _obj_0.make_symlink, _obj_0.ensure_path_exists
end
local File
do
  local _class_0
  local trim_margin
  local _parent_0 = StateObject
  local _base_0 = {
    check = function(self)
      local chk
      chk = function()
        if self.kind == 'directory' then
          if not (path.isdir(self.path)) then
            return false
          end
          return true
        end
        if not (is_symlink(self.path)) then
          return false
        end
        if not (path.link_attrib(self.path).target == self.source_file) then
          return false
        end
        if self.kind == 'inline' then
          local contents = file.read(self.path)
          if not (contents == self.inline_data) then
            return false
          end
        end
        return true
      end
      self.state = chk()
      if self.ensure == 'absent' then
        self.state = not self.state
      end
      return self.state
    end,
    enforce = function(self)
      local _exp_0 = self.ensure
      if 'present' == _exp_0 then
        if self.kind == 'directory' then
          if not (ensure_path_exists(self.path)) then
            return false
          end
          return true
        end
        if not (ensure_path_exists(tostring(var.cache_dir) .. "/.compiled")) then
          return false
        end
        if not (ensure_path_exists(tostring(path.dirname(self.path)))) then
          return false
        end
        if self.state then
          return true
        end
        if self.repo then
          if not (self.repo.state) then
            return false
          end
        end
        if path.isfile(self.path) then
          file.delete(self.path)
        end
        if path.isdir(self.path) then
          path.rmdir(self.path)
        end
        if self.kind == 'inline' then
          local ok, err = file.write(self.source_file, self.inline_data)
          if not (ok) then
            self:error("Failed to write data to " .. tostring(self.source_file))
            return false
          end
        end
        local ok, err = make_symlink(self.source_file, self.path)
        if not (ok) then
          self:error("Failed to link " .. tostring(self.path) .. " to " .. tostring(self.source_file))
          return false
        end
        return true
      elseif 'absent' == _exp_0 then
        local ok, err = file.delete(self.source_file)
        if not (ok) then
          self:error("Failed to delete source: " .. tostring(self.source_file))
          return false
        end
        ok, err = file.delete(self.path)
        if not (ok) then
          self:error("Failed to delete path: " .. tostring(self.path))
          return false
        end
        return true
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, filepath, state_tbl)
      need_type(filepath, 'string', 1)
      need_type(state_tbl, 'table', 2)
      if state_tbl.ensure then
        need_type(state_tbl.ensure, 'string', "state_tbl.ensure")
      else
        state_tbl.ensure = 'present'
      end
      local err_var
      state_tbl.ensure, err_var = valid_input(state_tbl.ensure, 'invalid', {
        'present',
        'absent'
      })
      self.name = path.expanduser(filepath)
      self.path = path.expanduser(filepath)
      self.ensure = state_tbl.ensure
      local _exp_0 = state_tbl.ensure
      if 'invalid' == _exp_0 then
        self:critical_error("Invalid ensure declaration for " .. tostring(self) .. " (got: " .. tostring(err_var) .. "}")
      elseif 'absent' == _exp_0 then
        self.kind = 'absent'
        need_type(state_tbl.source, 'nil', 'state_tbl.source')
        need_type(state_tbl.inline, 'nil', 'state_tbl.inline')
      else
        self.kind = need_one(state_tbl, {
          source = state_tbl.source,
          inline = state_tbl.inline,
          directory = state_tbl.directory
        })
      end
      local _exp_1 = self.kind
      if 'source' == _exp_1 then
        if strx.at(state_tbl.source, 1) == '@' then
          local repo_name = strx.lstrip(strx.split(state_tbl.source, ":")[1], '@')
          local repo_path = state_tbl.source:gsub("%@" .. tostring(repo_name) .. "%:", '')
          do
            self.repo = Repo.fetch(repo_name)
            if not self.repo then
              self:error("Missing required repo: " .. tostring(repo_name))
              return false
            end
          end
          if self.repo.ensure ~= 'present' then
            self:error("Cannot reference repo marked as " .. tostring(self.repo.ensure))
          end
          self.source_file = tostring(self.repo.path) .. "/" .. tostring(repo_path)
        else
          self.source_file = path.expanduser(state_tbl.source)
        end
        if self.ensure ~= 'absent' then
          need_type(self.source_file, 'string', tostring(self) .. ".source_file")
        end
      elseif 'inline' == _exp_1 then
        self.inline_data = state_tbl.inline
        self.source_file = tostring(var.cache_dir) .. "/.compiled/" .. tostring(depath(self.path))
        if state_tbl.margin then
          need_type(state_tbl.margin, 'number', 'state_tbl.margin')
          self.inline_data = trim_margin(self.inline_data, state_tbl.margin)
        end
        if self.ensure ~= 'absent' then
          need_type(self.source_file, 'string', tostring(self) .. ".source_file")
        end
      end
      return _class_0.__parent.__init(self)
    end,
    __base = _base_0,
    __name = "File",
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
  Config("indentation", '  ', function(want)
    return want
  end)
  trim_margin = function(str, margin)
    if margin < 1 then
      return str
    end
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
        line = line:gsub("^" .. tostring(var.indentation:rep(margin)), '')
        new_str = new_str .. (line .. "\n")
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return new_str
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  File = _class_0
end
local Template
do
  local _class_0
  local _parent_0 = File
  local _base_0 = {
    check = function(self)
      if self.kind == 'inline' then
        self.inline_data = self.rendered
      end
      if not (_class_0.__parent.__base.check(self)) then
        local state = false
        return self.state
      end
      if not (md5.sum(self.rendered) == md5.sum(file.read(self.path))) then
        local state = false
        return self.state
      end
      return true
    end,
    enforce = function(self)
      local _exp_0 = self.kind
      if 'source' == _exp_0 then
        file.write(self.source_file, self.rendered)
      elseif 'inline' == _exp_0 then
        self.inline_data = self.rendered
      end
      return _class_0.__parent.__base.enforce(self)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, filepath, state_tbl)
      _class_0.__parent.__init(self, filepath, state_tbl)
      if state_tbl.environment then
        need_type(state_tbl.environment, 'table', 'state_tbl.environment')
      end
      local err
      local tmpl
      local _exp_0 = self.kind
      if 'inline' == _exp_0 then
        tmpl, err = etlua.compile(self.inline_data)
      elseif 'source' == _exp_0 then
        tmpl, err = etlua.compile(file.read(self.source_file))
      end
      if err then
        self:error("Failed to render " .. tostring(self) .. ": " .. tostring(err))
        return false
      end
      self.rendered = tmpl(state_tbl.environment or { })
      self.source_file = tostring(var.cache_dir) .. "/.compiled/" .. tostring(depath(self.path))
    end,
    __base = _base_0,
    __name = "Template",
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Template = _class_0
end
sandbox_export({
  file = File,
  template = Template
})
return {
  File = File,
  Template = Template
}
