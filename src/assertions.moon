-- Assert that only one of the possible values provided is not nil
-- @param what_for The argument or data structure in question
-- @param want_tbl The data structure to be tested
-- @return The key of the winning table entry
need_one = (what_for, want_tbl) ->
  local wanted_for
  wanted_for = "arg #{what_for}" if type(what_for) == 'number'
  wanted_for = what_for if type(what_for) == 'string'

  found = false

  for k, v in pairs want_tbl
    assert (v != nil or (v == nil and not found)),
      "#{debug.getinfo(2).name}: more than 1 of possible values provided in #{wanted_for} (extra: #{found})"
    if v then found = k

  return found


--- Assert that var is the wanted type, and provide a standard error for when it is not
-- @param var The variable that will be tested
-- @param want The desired object type
-- @param what_for The argument or data structure that needs this type
need_type = (var, want, what_for) ->
  local wanted_for

  if what_for
    wanted_for = "arg #{what_for}" if type(what_for) == 'number'
    wanted_for = what_for if type(what_for) == 'string'

    assert type(var) == want,
      "#{debug.getinfo(2).name}: expected a #{want} for #{wanted_for}, got a #{type var}"

  else
    what_for = want
    wanted_for = "arg #{what_for}" if type(what_for) == 'number'
    wanted_for = what_for if type(what_for) == 'string'

    assert var != nil,
      "#{debug.getinfo(2).name}: got a nil for #{wanted_for}, required a variable"

{
  :need_one
  :need_type
}