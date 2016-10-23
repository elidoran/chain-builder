
class Control
  # TODO: consider array.slice() to make our own copy
  constructor: (@_chain, @_array, @_context, @_done) -> @_index = -1

  _resume: ->
    @_wasPaused = @paused
    @paused = null
    @_chain.emit 'resume', this # TODO: Not sure what to include here
    result = @_execute()
    results = @_chain._finish result, this
    return results

  # more readable for pipeline style to call next() and then do more work after it
  next: -> @_execute()

  context: (context, permanent) ->
    if permanent then @_context = context
    @_execute context

  _execute: (context) ->
    if @paused?  then throw new Error 'paused, can not perform _execute()'
    if @stopped? then throw new Error 'stopped, can not perform _execute()'
    if @failed?  then throw new Error 'failed, can not perform _execute()'

    loop
      @_index++
      index = @_index
      array = @_array
      if index < array.length
        try
          control = this
          context ?= @_context
          fn = array[index]
          fnThis = fn?.options?.this ? context
          result = fn.call fnThis, control, context
          context = null # don't reuse impermanently overridden context (_execute's arg)
        catch e then error = e

        return result if result?.error? # breaks the loop
        return error:error if error? # breaks the loop

        return result if @paused? or @stopped? or @failed? # breaks the loop

      else return true

  pause: (reason) ->  # provide a resume callback to switch to async processing
    @paused = reason:reason, index:@_index, fn:@_array[@_index]
    @_chain.emit 'pause', @paused
    return @_resume.bind this  # return as the `resume` function

  stop: (reason) ->
    @stopped = reason:reason, index:@_index, fn:@_array[@_index]
    result = context:@context
    @_chain.emit 'stop', result
    return true

  fail: (reason) ->
    @failed = reason:reason, index:@_index, fn:@_array[@_index]
    @_chain.emit 'fail', @failed
    return false

class Chain extends require('events').EventEmitter

  constructor: (options) ->
    array =
      if Array.isArray options then options
      else if typeof options is 'function' then [ options ]
      else if Array.isArray options?.array then options.array
      else if not options? then []

    @array = array

  add: (fns...) ->
    if Array.isArray fns?[0] then fns = fns[0] # unwrap array
    length = @array.length
    for fn in fns
      unless 'function' is typeof(fn) then return error:'must be a function',fn:fn
      # @array.push fn
    # no error, so, splice them all into there
    @array.splice @array.length, 0, fns...
    if length isnt @array.length then @emit 'add', fns
    return success:true

  remove: (fn) ->
    index = @array.indexOf fn
    result = {}
    if index > -1
      result.removed = @array.splice index, 1
      @emit 'remove', fn
    return result

  clear: ->
    if @array.length > 0      # only operate when there's some content
      array = @array          # remember the array
      @array = []             # new empty array = clear
      @emit 'remove', array   # emit a remove event with the array

  run: (options, done) ->
    context = options?.context ? {}                # get context or default to {}
    done = options?.done ? done                    # look for `done`
    control = new Control @, @array, context, done # create controller
    @emit 'start', control:control, chain:this
    result = control._execute()                    # starts the chain
    if control.paused?                             # a paused chain isn't done
      results = paused:control.paused              # return only paused info
    else                                           # we're done, synch'ly
      results = @_finish result, control           # include available info
    return results                                 # return results, synch'ly

  _finish: (result, control) ->
    results = result:result, context:control._context, chain:this
    results.stopped = control.stopped if control.stopped?
    results.failed  = control.failed  if control.failed?
    control._done? result.error, results
    @emit 'done', result.error, results
    return results


module.exports = (options) ->
  array =
    if Array.isArray options then options
    else if typeof options is 'function' then [ options ]
    else if Array.isArray options?.array then options.array
    else []

  # validate array's contents: must be functions
  for element,index in array
    unless 'function' is typeof(element)
      return error:'Elements must be functions', element:element, index:index

  new Chain array:array

module.exports.Chain = Chain
module.exports.Control = Control
