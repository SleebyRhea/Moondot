package = "moondot"
version = "dev-1"
source = {
  url = "https://github.com/SleepyFugu/moondot"
}
description = {
  homepage = "https://github.com/SleepyFugu/moondot",
  license = "bsd-3-clause"
}
dependencies = {
  "lua >= 5.1",
  "moonscript",
  "ansicolors",
  "penlight",
  "etlua",
  "md5"
}
build = {
  type = "builtin",
  modules = {
    ["moondot"] = "compiled/moondot.lua",
    ["moondot.obj"] = "compiled/moondot/obj.lua",
    ["moondot.obj.config"] = "compiled/moondot/obj/config.lua",
    ["moondot.obj.file"] = "compiled/moondot/obj/file.lua",
    ["moondot.obj.repo"] = "compiled/moondot/obj/repo.lua",
    ["moondot.obj.rock"] = "compiled/moondot/obj/rock.lua",
    ["moondot.obj.stateobject"] = "compiled/moondot/obj/stateobject.lua",
    ["moondot.env"] = "compiled/moondot/env.lua",
    ["moondot.utils"] = "compiled/moondot/utils.lua",
    ["moondot.oo_ext"] = "compiled/moondot/oo_ext.lua",
    ["moondot.output"] = "compiled/moondot/output.lua",
    ["moondot.assertions"] = "compiled/moondot/assertions.lua",
    ["moondot.command"] = "compiled/moondot/command.lua",
  },
  install = {
    bin = {
      ["moondot"] = "compiled/moondot.lua"
    }
  }
}
