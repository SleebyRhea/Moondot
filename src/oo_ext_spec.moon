describe "oo_ext.moon", ->
  it "can be loaded", -> require"src.oo_ext"

  it "can get class names", ->
    import
      what
      from require"src.oo_ext"

    class Test
    assert.are.equal 'Test', what Test!
    assert.are.equal 'table', what {}
    assert.are.equal 'string', what ''
    assert.are.equal 'number', what 1

  it "can check class equivalence", ->
    import
      is_a
      from require"src.oo_ext"

    class Test

    class Test2

    t1 = Test!
    t2 = Test2!

    assert.is_true is_a t1, Test
    assert.is_false is_a t1, Test2
    assert.is_false is_a t2, Test
    assert.is_true is_a t2, Test2