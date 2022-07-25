# Moondot
Dead simple dotfile management

## Installation
- Stable:
  ```
  luarocks install moondot
  ```
- Development:
  ```
  git clone https://github.com/SleepyFugu/moondot
  cd moondot
  luarocks make ./moondot-dev-1.rockspec
  ```

## HOWTO
- Create a file named .moondot in your home directory, and open it with your favorite editor
  ```
  touch ~/.moondot
  vim ~/.moondot
  ```
- Set the desired location for Moondot to save it's cache files (`~/.local/share/moondot_cache` by default)
  ```
  set "cache_dir", "~/Library/MoondotCache"
  ```
- Set any additional paths that you wish to access via `var`
  ```moonscript
  set "path", {
    bash: "/bin/bash"
    scripts:  "~/.local/bin"
    binaries: "~/.local/bin"
    profiled: "~/.local/profile.d"
  }
  ```
  - If you have OS specific state, `macos`, `linux`, and `bsd` are provided for now.
    ```
    macos ->

      set "path", {
        bash:     "/opt/homebrew/bin/bash"
      }
    ```

    repo "MyRepo/dotfiles"
    needed_dirs = { var.path.scripts, var.path.binaries, var.path.profiled }
    for _, d in ipairs needed_dirs
      file d, directory: true

  block "Files to clear", ->
    clear_files = { '~/.bash_aliases' }
    for _, f in ipairs clear_files
      file f, ensure: 'absent'

  block "Main RC files", ->
    template "~/.profile"
      source: '@SleepyFugu/dotfiles:env/.profile.etlua'
      environment: var.path
    file "~/.bashrc"
      source: '@SleepyFugu/dotfiles:env/.bashrc'
    file "~/.bash_profile"
      source: '@SleepyFugu/dotfiles:env/.bash_profile'

  block "User profile.d", ->
    file "#{var.path.profiled}/99-history.sh"
      source: '@SleepyFugu/dotfiles:env/profiled/99-history.sh'
    file "#{var.path.profiled}/99-rvm.sh"
      source: '@SleepyFugu/dotfiles:env/profiled/99-rvm.sh'

    macos ->
      file "#{var.path.profiled}/00-shutup-macos.sh"
        source: '@SleepyFugu/dotfiles:env/profiled/00-shutup-macos.sh'
      file "#{var.path.profiled}/00-aliases.sh"
        source: '@SleepyFugu/dotfiles:env/profiled/00-aliases.sh'
      template "#{var.path.profiled}/10-homebrew.sh"
        environment: var.path
        source: '@SleepyFugu/dotfiles:env/profiled/10-homebrew.sh.etlua'

  block "Luajit Devel Environment", ->
    lj_repo = repo "openresty/luajit2"
      creates: { "#prefix:bin/luajit" }
      builder: ->
        env.set_var "MACOSX_DEPLOYMENT_TARGET", "12.00"
        env.file.replace_lines "Makefile",
          "^export PREFIX=.*$",
          "export PREFIX=#{env.prefix}",
          limit: 1
        env.run "make"
        env.run "make", "install"
      cleaner: ->
        env.git.clean "-f"
        env.git.reset "--hard"

    var.path.luajit = lj_repo.prefix

    lr_repo = repo "luarocks/luarocks"
      creates: { "#prefix:bin/luarocks", "#prefix:bin/luarocks-admin" }
      builder: ->
        env.run "sh", "configure",
          "--prefix=#{env.prefix}",
          "--with-lua=#{env.luajit_pfx}",
          "--with-lua-include=#{env.luajit_pfx}/include/luajit-2.1",
          "--with-lua-lib=#{env.luajit_pfx}/lib"
        env.run "make"
        env.run "make", "install"
      cleaner: ->
        env.git.clean "-f"
        env.git.reset "--hard"
      environment:
        "luajit_pfx": var.path.luajit

    var.path.luarocks = lr_repo.prefix
    set 'luarocks', "#{var.path.luarocks}/bin/luarocks"
    set 'luarocks_prefix', var.path.luarocks

    template "#{var.path.luarocks}/etc/luarocks/config-5.1.lua",
      environment: var.path
      source: '@SleepyFugu/dotfiles:env/luarocks/config-5.1_luajit.lua.etlua'
    template "#{var.path.profiled}/10-luajit.sh"
      source: '@SleepyFugu/dotfiles:env/profiled/10-luajit.sh.etlua'
      environment: var.path
    template "#{var.path.profiled}/10-luarocks.sh"
      source: '@SleepyFugu/dotfiles:env/profiled/10-luarocks.sh.etlua'
      environment: var.path

    macos ->
      file "~/.libfix"
        chmod: '0600'
        margin: 4
        inline: [[
          -lzzip := -lzzip-0
        ]]

    file "#{var.path.scripts}/library_fixer"
      source: '@SleepyFugu/dotfiles:env/scripts/library_fixer.sh'
      chmod: '0700'

    rock "moonscript"
    rock "penlight"
    rock "lua-json"
    rock "lyaml"
    rock "luazip"
    rock "etlua"
    rock "md5"

    repo "Sleepyfugu/Moondot"
      creates: { "#{var.path.luarocks}/bin/moondot" }
      builder: ->
        env.del_var 'LUA_PATH'
        env.del_var 'LUA_CPATH'
        env.run "#{var.path.luarocks}/bin/luarocks", "make", "moondot-dev-1.rockspec"
      cleaner: ->
        env.git.clean "-f"
        env.git.reset "--hard"

  block "External Scripts", ->
    repo "Bijman/srb2bld"

    file "#{var.path.scripts}/srb2bld"
      source: "@Bijman/srb2bld:srb2bld"
      chmod:  '0700'

    macos ->
      file "#{var.path.profiled}/10-srb2bld.sh"
        source: '@SleepyFugu/dotfiles:env/profiled/10-srb2bld.sh'
  ```