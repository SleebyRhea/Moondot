package = "moonconf"
version = "dev-1"
source = {
  url = "https://github.com/SleepyFugu/Moonconf"
}
description = {
  homepage = "https://github.com/SleepyFugu/Moonconf",
  license = "bsd-3-clause"
}
dependencies = {
  "lua >= 5.1",
  "moonscript",
  "penlight",
}
build = {
  type = "builtin",
  modules = {
    ["moondot"] = "moondot.main.lua",
    ["moondot.obj"] = "moondot.obj.lua",
    ["moondot.obj.config"] = "moondot.obj.config.lua",
    ["moondot.obj.file"] = "moondot.obj.file.lua",
    ["moondot.obj.repo"] = "moondot.obj.repo.lua",
    ["moondot.obj.stateobject"] = "moondot.obj.stateobject.lua",
    ["moondot.env"] = "moondot.env.lua",
    ["moondot.utils"] = "moondot.utils.lua",
    ["moondot.oo_ext"] = "moondot.oo_ext.lua",
    ["moondot.output"] = "moondot.output.lua",
    ["moondot.assertions"] = "moondot.assertions.lua",
  },
  install = {
    bin = { "bin/moondot" }
  }
}
