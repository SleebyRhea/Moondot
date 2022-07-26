# Moondot
Dead simple user-local configuration management

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
        bash: "/opt/homebrew/bin/bash"
      }
    linux ->
      set "path", {
        bash: "/bin/bash"
      }
    ```
- Add any basic github repositories that you wish to have tracked:
  ```
  repo "MyRepo/dotfiles"
  ```
- Moondot supports small number of objects that can be used to easily denote user-level configuration files.
  - Really, it could conceivably manage any configuration with enough permissions but safety is NOT guaranteed. Go use one of the major configuration management vendors if you wish to modify system-level configurations.

### Config
- Moondot uses a simple configuration style with configurations evaluated at runtime and adjusted/accessed via the `set` and `var` objects respectively. You can only run `set` on configuration objects that were previously defined within the Moondot source and any plugins, and you cannot create new configurations within your local `.moondot` file. An example of the usage of `set` is as follows:
  ```
  -- This will set Config[cache_dir] for Moondot to "~/Library/MoondotCache"
  set "cache_dir", "~/Library/MoondotCache"

  -- This will set Config[path] to be a table with a reference to the denoted Bash location
  set "path", {
    bash: "/opt/homebrew/bin/bash"
  }
  ```
- The use of `set` will run the provided values through a validation function, which should prevent most runtime errors.
- Read access of `Config[]` objects is handled the `var` object. Below, is an example of this usage:
  ```
  -- This will set Config[cache_dir] for Moondot to "~/Library/MoondotCache"
  set "path", { some_path: "filepath" }

  -- This will use the previously assigned Config[path] to setup the File[some_path] entry that points to a file containing the contents of Config[path].some_path
  file var.some_path
    inline: "#{var.some_path}"
  ```

### File
- The primary object is the `File[]` object. It allows you to denote either inline or via a source file, the contents of a target. You may also set the permissions for file via `chmod`. Here is a very basic example:
  ```
  file "~/.bashrc"
    source: "<some filepath>"
    chmod: "0600
  ```
- File allows you to specify a previously initialized repository to look for a file. Files with sources such as this one will begin looking for the file at the root of the repository.
  ```
  file "~/.bashrc"
    source: "@<repo owner>/<repo name>:<some repo file>"
  ```
- Files can also have their contents provided within the root configuration file, via the `inline` content specifier. Optionally, this can also be provided with a `margin` specifier to denote how many indentations there are preceding the inline data
  ```
  file "~/.bashrc"
    margin: [optional] <number of indent for inline>
    inline: "<some string>"
  ```
  - Note, that the default indent is 2 consecutive spaces. To adjust this, and allow your files to be loaded correctly, you must ensure that you have set `Config[indentation]` accordingly. See the configuration section for how to do that.
  - Also note that you may specify _either_ `source` or `inline`. Not both simultaneously.

### Template
- Moondot provides support for Etlua templates via the `Template[]` object. With the exception of one addition, the `Template[]` object is identical to `File[]` in semantics. It supports both `source` and `inline` (though as with `File[]`, only one per entry) and also supports the optional `margin`.
- Additionally, `Template[]` will pass the contents of `environment` to the Etlua template to use as it's local environment.
- Here is a full example utilizing the `Command[]` object with `inline`:
  ```
  template "~/.some_pkg_config_info"
    environment: {
      somelib_cfg: -> command("pkg-config") "somelib", "--libs", "--cflags"
    }
    chmod: '0600'
    margin: 4
    inline: [[
      results of pkg-config: <%- somelib_cfg() %>
    ]]
  ```

### Rock
- Moondot allows you to specify Rocks that you wish to have installed via your preferred `luarocks` binary. To use this object type, you must specify the `Config[luarocks]` to the location of your preferred luarocks binary. See the configuration section for how to do that.
- Usage is simple, simply provide the rock name as such to install a rock:
  ```
  rock "moonscript"
  ```
- Some rocks require extra variables to be provided on the command line (anything related to openssl for example). To accomodate that, you can provide the object with a table of keys that will be provided to Luarocks. Example:
  ```
  rock "http"
    variable_dirs: {
      CRYPTO_DIR: "/path/to/openssl/1.1/1.1.1q"
      OPENSSL_DIR: "/path/to/openssl/1.1/1.1.1q"
    }
  ```


### Repo
- The core of Moondot is the `Repo[]` object, which allows you to track github repos, keep your local tree up-to-date, and even build the contents thereof if required using the `builder` specifier. Here is a very basic example of a repo that is initialized and tracked, and with a single file that references it:
  ```
  repo "RepoOwner/my-repo"
  file "~/.file_here"
    source: "@RepoOwner/my-repo:file_here"
  ```
- Alternatively, the `install` specifier can be used in place of an additional `File[]` object:
  ```
  repo "RepoOwner/my-repo"
    install:
      { "#repo:<file in repo root>", "<link>" }
  ```
- Each repo has an accompanying prefix (ala a private `/usr`, `/var`, `/etc`) accessible to various specifiers by using the `#prefix:<filepath>` denotation
- More usefully, repo can use the `builder` specifier to build a repository that needs to be kept up-to-date. To facilitate this, the following functions are provided to builders (and cleaners) through the `env` variable:
  - `env.prefix`: The repos prefix
  - `env.del_var(key)`: Deletes the provided key from the list of environmental variables passed to subsequent commands
  - `env.set_var(key, val)`: Sets the provided key to the value, and provides said value to subsequent commands
  - `env.git.<command>(option, ...)`: Run `git-<command>` within the repos root and with the provided options
  - `env.run(command, option, ...)`: Run the provided shell command with the given options. If a table is provided, it's keys are added to the environment of the command
  - `env.file.replace_lines(file, match, replace, config)`: Replace the matched lines in a file
    - `config` should be a table or nil, and (for now) merely allows you to set the limit of replacements via `config:limit:<number>`
- `cleaner` _must_ be specified and is what is used to clean the repository between builds
- `creates` is an optional specifier, that specifies files that the provided builder will be creating
- Here is a full example of building luarocks from source using the repo builder, and using it to set `Config[luarocks_prefix]`
  ```
  set "path"
    luajit_pfx: /opt/luajit

  lr_repo = repo "luarocks/luarocks"
    -- Note the use of #prefix: here, as the builder creates those files and places them
    -- within the repos prefix directory
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

  set 'luarocks', "#{lr_repo.path}/bin/luarocks"
  set 'luarocks_prefix', lr_repo.prefix
  ```