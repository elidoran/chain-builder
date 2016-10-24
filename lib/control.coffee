
module.exports = class Control

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
