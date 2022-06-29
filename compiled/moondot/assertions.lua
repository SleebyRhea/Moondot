local need_one
need_one = function(what_for, want_tbl)
  local wanted_for
  if type(what_for) == 'number' then
    wanted_for = "arg " .. tostring(what_for)
  end
  if type(what_for) == 'string' then
    wanted_for = what_for
  end
  local found = false
  for k, v in pairs(want_tbl) do
    assert((v ~= nil or (v == nil and not found)), tostring(debug.getinfo(2).name) .. ": more than 1 of possible values provided in " .. tostring(wanted_for) .. " (extra: " .. tostring(found) .. ")")
    if v then
      found = k
    end
  end
  return found
end
local need_type
need_type = function(var, want, what_for)
  local wanted_for
  if what_for then
    if type(what_for) == 'number' then
      wanted_for = "arg " .. tostring(what_for)
    end
    if type(what_for) == 'string' then
      wanted_for = what_for
    end
    return assert(type(var) == want, tostring(debug.getinfo(2).name) .. ": expected a " .. tostring(want) .. " for " .. tostring(wanted_for) .. ", got a " .. tostring(type(var)))
  else
    what_for = want
    if type(what_for) == 'number' then
      wanted_for = "arg " .. tostring(what_for)
    end
    if type(what_for) == 'string' then
      wanted_for = what_for
    end
    return assert(var ~= nil, tostring(debug.getinfo(2).name) .. ": got a nil for " .. tostring(wanted_for) .. ", required a variable")
  end
end
return {
  need_one = need_one,
  need_type = need_type
}
