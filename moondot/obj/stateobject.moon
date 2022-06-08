color = require"ansicolors"

import
  dump
  from require"pl.pretty"

import
  valid_input
  from require"moondot.utils"

import
  getters
  setters
  private
  from require"moondot.oo_ext"

import
  emit
  from require"moondot.output"

class StateObject
  data = private @

  error: (msg) =>
    emit "%{red}#{@}: #{msg}"

  critical_error: (msg) =>
    @error msg
    os.exit 1

  new: =>
    cls_name = @.__class.__name
    if data[@.__class][@name]
      @critical_error "#{cls_name}[#{@name}] - Cannot track a #{cls_name} more than once!"

    data[@.__class][@name] = @
    table.insert data[@.__class].children, @

  track: () =>
    data[@.__class][@name] = @

  __inherited: (child) =>
    data[child.__class] = {}
    data[child.__class].children = {}

    child.__class.__base.__tostring = =>
      "#{@__class.__name}[#{@name}]"

    -- Inject helper methods for state tracking as simple Class functions
    -- These are done here, as they are not intended to be methods
    child.__class.count = () -> #(data[child.__class].children)
    child.__class.fetch = (name) -> data[child.__class][name]
    child.__class.each = (fn) ->
      for k, v in pairs data[child.__class].children
        fn v

    if not child.__class.__base.enforce
      child.__class.__base.enforce = () =>
        @state = true
        return true
    else
      child_enforce = child.__class.__base.enforce
      child.__class.__base.enforce = (...) =>
        @state = child_enforce @, ...
        return @state


{
  :StateObject
}