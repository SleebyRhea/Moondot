local color = require("ansicolors")
local strx = require("pl.stringx")
local need_type
need_type = require("moondot.assertions").need_type
local margin_size = 0
local output_margin = ''
local update_margin
update_margin = function(num)
  need_type(num, 'number', 1)
  margin_size = margin_size + num
  output_margin = (' '):rep(2 * margin_size)
end
local emit
emit = function(message)
  return print(color(tostring(output_margin) .. tostring(message)))
end
local run_with_margin
run_with_margin = function(func)
  need_type(func, 'function', 1)
  update_margin(1)
  local ret = {
    func()
  }
  update_margin(-1)
  return unpack(ret)
end
local insert_margin
insert_margin = function(str)
  local new_str, str_lines = '', strx.splitlines(str)
  for i, line in ipairs(str_lines) do
    new_str = new_str .. tostring(output_margin) .. tostring(line) .. "\n"
  end
  return new_str
end
return {
  emit = emit,
  insert_margin = insert_margin,
  run_with_margin = run_with_margin
}
