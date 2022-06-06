strx  = require"pl.stringx"
color = require"ansicolors"

import
  need_type
  from require"src.assertions"

margin_size  = 0
output_margin = ''

--- Update the output margin size by the given amount
-- @param number Size to increase margin by
-- @return None
update_margin = (num) ->
  need_type num, 'number', 1

  margin_size += num
  output_margin = (' ')\rep 2 * margin_size


--- Emit a message using the output margin
-- @param message Message to be emitted
-- @return None
emit = (message) ->
  print color "#{output_margin}#{message}"


--- Increment the output margin size, run a function, and decrement when completed
-- @param func Function to be called
-- @return Return values of func
run_with_margin = (func) ->
  need_type func, 'function', 1

  update_margin 1
  ret = {func!}
  update_margin -1

  return unpack ret

{
  :emit
  :run_with_margin
}