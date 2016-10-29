###
  Control manages a single execution process for a Chain and provides advanced
  functionality to the functions called in the chain.
###
module.exports = class Control

  # TODO: consider array.slice() to make our own copy
  constructor: (@_chain, @_array, @_context, @_done) -> @_index = -1


  # returned (bound) by the pause() function
  _resume: ->
    # TODO: do we honor chain.disable() during an active execution?
    # it's possible to disable the chain during a pause. should we check
    # for chain._disabled? and refuse to resume?
    # if @_chain._disabled? # if we're disabled then tell them
    #   return result:false, reason:'Chain is disabled', disabled:@_chain._disabled

    # eliminate the pause info because we're no longer paused
    @paused = null

    # when we resume, check for a fail() result.
    unless @failed?

      # let everyone know we're resuming now
      @_chain.emit 'resume', this # TODO: Not sure what to include here

      # begin executing again. this restarts the sync style execution with a return
      result = @_execute()

    # okay, we failed, don't execute, result is false.
    else result = false

    # once done executing, create the sync results and return them
    results = @_chain._finish result, this

    return results

  # sub-function on `_resume` (when returned, bound, by pause()).
  # it helps create a (error, result) style callback function.
  # use defaults...
  _resumeCallback: (errorMessage = 'ERROR', resultKey = 'result') ->
    # when called, we're attached to the "resumer".
    resumer = this
    control = resumer.control

    # the standard param pattern has error first and result second
    (err, res) ->

      # if there's an error, then fail with both message and the Error
      if err? then control.fail errorMessage, err

      # otherwise, store the result into the context with the key, then resume.
      else control._context[resultKey] = res

      resumer()

  # continues executing the chain and then returns to the calling function.
  # optionally perform a temporary or permanent context change.
  # if a function wants to do work after the rest of the chain has executed,
  # then it calls next(), which returns once the rest are done.
  # Note: that's for sync processing. if they pause(), then, that'll return
  # to them as the result with the 'paused' info.
  next: (context, permanent) ->

    # don't call @context() because we'll pass context to _execute() below.
    # do check if it's a permanent change tho. do that if it's true.
    if permanent then @_context = context

    # if we set an index to use on the next call, then use it now
    if @__index?
      # remember the index which was set, and change the active index to it
      index = @_index = @__index

      # remove the set index for future calls
      # (as we backup their after execute() step will overwrite this anyway...?)
      delete @__index

    else # remember the index as it is right now.
      index = @_index

    # begin executing the chain again using this new context.
    # without the 'permanent' overwrite above, this will only be used to call
    # the next function before being dropped.
    result = @_execute context

    # before exiting this function, mark the index we remembered in case
    # they call this next() again
    @__index = index

    # return the result back to the caller of next()
    return result

  # this allows changing the context for the next function called, or,
  # permanently changing the context for all calls and the return result.
  context: (context, permanent) ->

    # if they specify 'permanent' then overwrite our stored context with this one
    # this ensures it will be used from now on
    if permanent then @_context = context

    # remember it for the next run only
    else @_nextContext = context

    return

  # this is the main function to execute the chain
  _execute: (context) ->
    # these shouldn't ever happen... # TODO: change to return error:'...'
    if @paused?  then throw new Error 'paused, can not perform _execute()'
    if @stopped? then throw new Error 'stopped, can not perform _execute()'
    if @failed?  then throw new Error 'failed, can not perform _execute()'

    # loop thru executing functions unless paused/stopped/failed
    loop

      # if remove() was called, then, instead of moving the index forward,
      # remove the current function.
      if @_remove?

        # get rid of the marker
        reason = @_remove
        delete @_remove

        # remove the function and remember it for an emit
        fn = @_array.splice @_index, 1

        # let's store the removal into context (the eventual return result)
        @removed ?= []
        # unwrap it from the array splice() puts it in
        @removed.push fn[0]

        # emit the removal
        @_chain.emit 'remove', result:true, removed:fn, reason:reason

      else # otherwise, move forward to the next function

        @_index++

        # keep incrementing while the function is disabled
        @_index++ while @_array?[@_index]?.options?.disabled?

      # local aliases
      index = @_index
      array = @_array

      # if there's more to do
      if index < array.length
        # wrap it to prevent a thrown error from taking over control
        try
          # local aliases (for readability)
          control = this
          fn = array[index]
          # either: 1. give as a param; 2. set with context(); 3. default context
          context = context ? @_nextContext ? @_context
          # now forget that one
          @_nextContext = null

          # check if the `fn` is disabled

          # did they specify a `this` to use instead of the context?
          fnThis = fn?.options?.this ? context

          # call the function with each important part
          result = fn.call fnThis, control, context

          # don't reuse *impermanently* overridden context (_execute's arg)
          # in the next loop iteration.
          context = null

        catch e then return control.fail 'caught error', e

        # break the loop if we have an error to return
        return result if result?.error?

        # break the loop if they said so
        return result if @paused? or @stopped? or @failed?

      # we made it all the way
      # TODO:
      #  make it possible for a function to alter the result returned
      #  back to the _execute() call.
      else return true


  # provides a resume() callback to switch to async processing
  pause: (reason) ->
    # remember we paused, store the reason and related info
    @paused = reason:reason, index:@_index, fn:@_array[@_index]

    # let everyone know the chain paused
    @_chain.emit 'pause', @paused

    # return @_resume as the `resume` function. bind it to this `control`
    resumer = @_resume.bind this

    # the resumer.callback() execution can grab `control` from this
    resumer.control = this

    # also, for convenience, add the ability to generate a standard callback
    # function with param pattern (error, result).
    # accepts an error message and a key name to place the result into the context.
    resumer.callback = @_resumeCallback

    return resumer

  # stops executing the chain with the reason provided
  stop: (reason) ->
    # remember we stopped, store the reason and related info
    @stopped = reason:reason, index:@_index, fn:@_array[@_index]

    # let's emit both the context and the stopped info
    result = context:@_context, stopped:@stopped

    # let everyone know we stopped
    @_chain.emit 'stop', result

    # return true. sure, we stopped, but that's not an error or failure
    return true


  fail: (reason, error) ->
    # remember we failed, store the reason and related info
    @failed = reason:reason, index:@_index, fn:@_array[@_index]

    # if they provided an error instance, then add it in
    if error? then @failed.error = error

    # let's emit both the context and the 'failed' info
    result = context:@_context, failed:@failed

    # let everyone know we 'failed'. provide the related info
    @_chain.emit 'fail', result

    # return false because we failed.
    return false


  # should this accept args like chain.remove() does?
  # right now, it only allows a function to remove itself.
  # it 'could' specify an id or index to remove another function.
  # simply record this was called, then, when execution steps back into
  # the `control` it can remove the function
  remove: (reason = true) ->
    @_remove = reason
    return true


  # start, temporarily, skipping execution of the current function.
  # record a reason in case someone wants to know.
  # Note: no matching control.enable() because the function will not run
  # while it's disabled. Use chain.enable()
  disable: (reason = true) -> @_chain._disable @_array[@_index], @_index, reason
