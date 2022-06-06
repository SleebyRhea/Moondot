

describe "obj.moon", ->
  it "can be loaded", ->
    require"src.obj"

describe "obj.moon::repo", ->
  it "is not nil", ->
    assert.is.truthy require("src.obj").repo
    assert.is.truthy require("src.obj").repo.Repo

  import
    Repo
    from require("src.obj").repo

describe "obj.moon::file", ->
  it "is not nil", ->
    assert.is.truthy require("src.obj").file
    assert.is.truthy require("src.obj").file.File
    assert.is.truthy require("src.obj").file.Template

  import
    File
    Template
    from require("src.obj").file

  it ""
