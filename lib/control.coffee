###
  Control manages a single execution process for a Chain and provides advanced
  functionality to the functions called in the chain.
###
module.exports = class Control

  constructor: (@_chain, @_array, @_context) ->

    # start at -1 cuz _execute increments by one at its beginning.
    @_index = -1

    # set properties now for use later so we're not adding them in later.
    @removed = null
    @paused  = null
    @stopped = null
    @failed  = null
    @__index = null
    @_nextContext = null


  # returned in an object by the pause() function
  _resumer: ->

    # TODO: do we honor chain.disable() during an active execution?
    # it's possible to disable the chain during a pause. should we check
    # for chain._disabled? and refuse to resume?
    # if @_chain._disabled? # if we're disabled then tell them
    #   return result:false, reason:'Chain is disabled', disabled:@_chain._disabled

    control = @control

    # eliminate the pause info because we're no longer paused
    control.paused = null

    if control.failed? then result = false

    else if control.stopped? then result = true

    else # we continue executing where we left off

      # let everyone know we're resuming now
      control._chain.emit 'resume', chain:control._chain # TODO: Not sure what to include here

      # begin executing again. this restarts the sync style execution with a return
      result = control._execute()

    # once done executing, create the sync results and return them
    control._chain._finish result, control


  # returned in an object by the pause() function
  _stopper: (reason) ->

    control = @control
    control.paused = null
    control.stop reason
    control._chain._finish true, control


  # returned in an object by the pause() function
  _failer: (reason, error) ->

    control = @control
    control.paused = null
    control.fail reason, error
    control._chain._finish false, control


  # sub-function on `_resume` (when returned, bound, by pause()).
  # it helps create a (error, result) style callback function.
  # use defaults...
  _resumeCallback: (errorMessage, resultKey) ->

    message = errorMessage ? 'ERROR'
    key     = resultKey ? 'result'

    # when called, we're attached to an object with the `control`.
    actions = this
    {control} = this

    # the standard param pattern has error first and result second
    (err, res) ->

      # if there's an error, then fail with both message and the Error
      if err? then control.fail message, err

      # otherwise, store the result into the context with the key
      else control._context[key] = res

      # then, either way, we resume execution.
      actions.resume()


  # continues executing the chain and then returns to the calling function.
  # optionally perform a temporary or permanent context change.
  # if a function wants to do work after the rest of the chain has executed,
  # then it calls next(), which returns once the rest are done.
  # Note: that's for sync processing. if they pause(), that returns a
  # result with the 'paused' info.
  next: (context, permanent) ->

    # don't call @context() because we'll pass context to _execute() below.
    # do check if it's a permanent change tho. do that if it's true.
    if permanent then @_context = context ? {}

    # if we already set an index to use on the next call, then use it now
    if @__index?

      # remember the index which was set, and change the active index to it
      index = @_index = @__index

      # remove the set index for future calls
      # (as we backup, will their "after execute()" step overwrite this anyway...?)
      @__index = null

    # remember the index as it is right now.
    else index = @_index

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
    if permanent then @_context = context ? {}

    # remember it for the next run only
    else @_nextContext = context

    return


  # call the function with each important part.
  # wrap it to prevent a thrown error from taking over control.
  # this function isolates the try-catch because earlier than Node 5.1
  # a function isn't optimized when it has a try-catch.
  _call: (fn, thiz, context) ->
    try
      # this = `control`
      fn.call thiz, this, context

    catch err
      @fail 'caught error', err


  _handleRemove: ->

    # remember the reason so we can remove the stored property
    reason = @_remove

    # get rid of the marker
    @_remove = null

    # remove the function and remember it for an emit.
    # extract it from the array result splice() provides
    fn = @_array.splice(@_index, 1)[0]

    # let's store the removal into context (the eventual return result)
    # create the array if it doesn't exist yet.
    @removed ?= []

    # add to the array
    @removed[@removed.length] = fn

    # emit the removal
    @_chain.emit 'remove', removed:fn, reason:reason, chain:@_chain

    return


  _nextIndex: ->

    array = @_array
    index = @_index + 1

    # keep incrementing thru disabled functions.
    # NOTE: must null-check element to stop at the end of the array.
    index++ while array[index]?.options?.disabled?

    return index


  # this is the main function to execute the chain
  _execute: (context) ->

    # these shouldn't ever happen...
    ### istanbul ignore next ###
    if @paused?  then return error: 'paused, can not perform _execute()'
    ### istanbul ignore next ###
    if @stopped? then return error: 'stopped, can not perform _execute()'
    ### istanbul ignore next ###
    if @failed?  then return error: 'failed, can not perform _execute()'

    # loop thru executing functions unless paused/stopped/failed
    loop

      # if remove() was called, then, instead of moving the index forward,
      # remove the current function.
      if @_remove? then @_handleRemove()

      # otherwise, move forward to the next function
      else @_index = @_nextIndex()


      # if there's more to do
      if @_index < @_array.length

        # our next function to execute. (local alias for readability)
        fn = @_array[@_index]

        # either:
        #   1. given as a param to this _execute() call
        #   2. set with context() (either temp or perm)
        #   3. default context
        context = context ? @_nextContext ? @_context

        # now forget the temporary one (may already be null)
        @_nextContext = null

        # use a specified `this` over the context
        thiz = fn.options?.this ? context

        # call the function with its "this" and context.
        # NOTE: in its own function, _call, to isolate try-catch.
        result = @_call fn, thiz, context

        # don't reuse *impermanently* overridden context (_execute's arg)
        # in the next loop iteration.
        # (basically, force it to reevaluate which context to use)
        context = null

        # break the loop if they said so
        return result if @paused? or @stopped? or @failed?

      # we made it all the way thru the array of functions to execute.
      # TODO:
      #  make it possible for a function to alter the result returned
      #  back to the _execute() call.
      else return true


  # provides a resume() callback to switch to async processing
  pause: (reason) ->
    # remember we paused, store the reason and related info
    @paused =
      reason: reason ? true
      index : @_index
      fn    : @_array[@_index]

    # let everyone know the chain paused
    @_chain.emit 'pause', paused:@paused, chain:@_chain

    # # return actions, the control, and the callback maker
    # 1. can reference the control property here instead of being bound.
    # 2. allows resume()'ing\
    # 3. allows stop()'ing instead of resuming.
    # 4. allows fail()'ing instead of resuming.
    # 5. also, for convenience, add the ability to generate a standard callback
    #    function with param pattern (error, result).
    #    accepts an error message and a key name to place the result into the
    #    context.

    control : this
    resume  : @_resumer
    stop    : @_stopper
    fail    : @_failer
    callback: @_resumeCallback


  # stops executing the chain with the reason provided
  stop: (reason) ->

    # remember we stopped, store the reason and related info
    @stopped =
      reason: reason ? true
      index : @_index
      fn    : @_array[@_index]

    # let's emit both the context and the stopped info
    result =
      context: @_context
      stopped: @stopped
      chain  : @_chain

    # let everyone know we stopped
    @_chain.emit 'stop', result

    # return true. sure, we stopped, but that's not an error or failure
    return true


  fail: (reason, error) ->

    # remember we failed, store the reason and related info
    @failed =
      reason: reason ? true
      index : @_index
      fn    : @_array[@_index]
      error : error

    # let's emit both the context and the 'failed' info
    result =
      context: @_context
      failed : @failed
      chain  : @_chain

    # let everyone know we 'failed'. provide the related info
    @_chain.emit 'fail', result

    # return false. we failed.
    return false


  # should this accept args like chain.remove() does?
  # right now, it only allows a function to remove itself.
  # it 'could' specify an id or index to remove another function.
  # simply record this was called, then, when execution steps back into
  # the `control` it can remove the function
  remove: (reason) ->
    @_remove = reason ? true
    return true


  # start, temporarily, skipping execution of the current function.
  # record a reason in case someone wants to know.
  # Note: no matching control.enable() because the function will not run
  # while it's disabled. Use chain.enable()
  disable: (reason) ->
    @_chain._disable @_array[@_index], @_index, reason ? true
