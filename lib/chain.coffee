getOptions = require './get-options'
Control    = require './control'

###
  Chain holds an array of functions to execute in sequence managed by a Control.
###
module.exports = class Chain extends require('events').EventEmitter

  constructor: (options) ->

    # if module's builder function already validated the array then use it
    # and avoid redoing that same work
    if options?.__validated then array = options.array

    # otherwise, let's be safe, must find the array and validate it
    else
      options = getOptions options

      # can't return a value from constructor, so, throw Error
      if options?.error? then throw new Error options.error

      array = options.array

    # an array of functions, so simple, until you wrap a Chain around it...
    @array = array

    # store the base of the context object (optional)
    @_base  = options?.base
    @_props = options?.props

    # when a new context builder is specified then move default one to new prop
    if options?.buildContext?
      @_originalBuildContext = @_buildContext
      @_buildContext = options.buildContext

    # all done
    return

  # add functions to the array:
  #  chain.add fn
  #  chain.add fn1, fn2, fn3, ...
  #  chain.add [ fn1, fn2, ... ]
  add: (fns...) ->

    # unwrap array
    if Array.isArray fns?[0] then fns = fns[0]

    # remember how many we already have
    length = @array.length

    # ensure each one is actually a function
    for fn in fns
      unless 'function' is typeof(fn) then return error:'must be a function', fn:fn

    # append them into the array via splice()
    @array.splice @array.length, 0, fns...

    # build our result for both emit and return
    result = result:true, added:fns, chain:this

    # if length is different then we actually added some, so emit 'add'
    # Note: this exists because it's possible to call add with nothing and
    # it would still emit an 'add' event despite not adding anything
    if length isnt @array.length then @emit 'add', result

    # it's all good
    return result


  # remove function from the array via: index, id, or the function itself
  #  chain.remove 3
  #  chain.remove 'some-id'
  #  chain.remove fn1
  remove: (which, reason) ->

    # find it based on the selector. may return an error
    index = @_findIndex which

    # if there's an error then we're done, return it
    if index?.error? then return index

    # use sub-operation so the select() stuff can also use the sub-operation.
    # select() one passes the function first and then the index
    @_remove null, index, reason

  # used by both chain.remove() and chain.select(...).remove()
  _remove: (_, index, reason = true) ->

    # by default, return an empty object because we didn't remove anything
    result = result:false, reason:reason, chain:this

    # if we found it tho
    if index > -1
      # then remove it from the array and assign it into the result
      result.removed = @array.splice index, 1

      # we succeeded
      result.result = true

      # let everyone know we removed it
      @emit 'remove', result

    else result.reason = 'not found'

    # and return the result whether it's empty or not
    return result


  # temporarily disable the whole chain or function(s) in the chain
  #   all:
  #     chain.disable()
  #     chain.disable('cuz i say so')
  #   one:
  #     chain.disable(3, 'reason')            - disable the fourth function
  #     chain.disable('someid', 'reason')     - disable the function with id 'someid'
  #     chain.disable(someFunction, 'reason') - disable that function
  #
  # NOTE: the only way to differentiate between:
  #  1. disable the whole chain with a reason, and,
  #  2. disable a function with the specified id,
  #  is to require a reason arg when specifying a function id as the first arg.
  #
  # so:
  #  1. all:   chain.disable('my reason to disable the whole chain')
  #  2. by id:
  #       chain.disable('someid', true)
  #       chain.disable('someid', 'reason for this one function to be disabled')
  #       chain.disable('someid', { some: 'object'})
  disable: (which, reason) ->

    # if they didn't pass any args then disable the whole chain and emit 'disable'
    if arguments.length is 0 or (arguments.length is 1 and typeof which is 'string')
      reason = which ? true
      @_disabled = reason
      result = result:true, reason:reason, chain:this
      @emit 'disable', result
      return result

    # find it based on the selector. may return an error
    index = @_findIndex which

    # if there's an error then we're done, return it
    if index?.error? then return index

    # get the fn
    fn = @array[index]

    # use sub-operation so the select() stuff can also use the sub-operation.
    # select() one passes the function first and then the index.
    @_disable fn, index, reason

  # the select() action passes the index as the second arg and the reason
  # is bumped to the third arg.
  _disable: (fn, _, reason = true) ->

    # store the reason, create its options object if it's not there
    if fn.options? then fn.options.disabled = reason
    else fn.options = disabled: reason

    # create our result
    result = result:true, fn:fn, reason:reason, chain:this

    # tell everyone
    @emit 'disable', result

    # all done
    return result


  # remove the `disabled` marker from a function, or this chain, if it exists,
  # and emit an 'enable' event.
  # all:
  #   chain.enable()
  # one:
  #   chain.enable(2)
  #   chain.enable('someid')
  #   chain.enable(someFunction)
  enable: (which) ->

    # if there's no arg, or which doesn't exist, then enable the whole chain.
    # Note: they could pass a null/undefined arg meaning to provide a value
    # to identify a single function, and, because of `or not which?` we would
    # enable the whole chain... so, don't use `or not which?` and let it
    # return an error.
    if arguments.length is 0 #or not which?

      # create our result, defaults to false
      result = result:false, chain:this

      # ensure the chain is actually disabled...
      if @_disabled?

        # remove the disable marker
        delete @_disabled

        # now it's successful
        result.result = true

        #tell everyone
        @emit 'enable', result

      # tell them why we failed to disable
      # Note: this isn't an error, only a reason why we didn't do any enabling
      else result.reason = 'chain not disabled'

      return result

    # otherwise, they're trying to disable a single function...
    else

      # find it based on the selector. may return an error
      index = @_findIndex which

      # if there's an error then we're done, return it
      if index?.error? then return index

      # get the fn
      fn = @array[index]

      # call sub-operation
      @_enable fn

  _enable: (fn) ->

    # create our result, defaults to false
    result = result:false, fn:fn, chain:this

    # ensure it actually is disabled...
    if fn?.options?.disabled?

      # remove the disable...
      delete fn?.options?.disabled

      # now it's successful
      result.result = true

      # tell everyone
      @emit 'enable', result

    else result.reason = 'function not disabled'

    return result

  # used to find the index of a function based on index, id, or itself
  _findIndex: (which) ->

    switch typeof which # which kind of value did we get

      when 'string' # it's an id of a function, so find it

        for fn, i in @array
          if which is fn?.options?.id then return i

        # TODO:
        # return error: 'unknown id', id: which
        return -1 # we didn't find it!

      when 'number' # they provided an index to use...
        # if that's a valid index then return it
        if 0 <= which < @array.length then return which

        # otherwise, return an error about it
        else return error:'Invalid index: ' + which # TODO: separate `which`

      # find the function in the array
      when 'function' then return @array.indexOf which
        # TODO:
        # index = @array.indexOf which
        # if index > -1 then return index
        # else error: 'unknown function', fn: which

      # woh! no good
      else
        error: 'Requires a string (ID), an index, or the function'
        which: which


  # empty the chain of all functions and let everyone know
  clear: () ->

    result =                  # create a result for both emit and return
      result: false
      chain : this

    if @array.length > 0      # only operate when there's some content to clear
      array = @array          # remember the array
      @array = []             # new empty array means we're cleared
      result.result = true    # we succeeded
      result.removed = array  # provide what we removed
      @emit 'clear', result   # emit a remove event with the array we removed

    else
      # on second thought, an already empty array *is* a success...
      result.result = true
      result.reason = 'chain empty'

    return result


  # used to perform sub-operations on functions chosen by select() operation
  _actor: (selector, action, args...) ->
    # alias
    chain = this

    # create two spots in args for our 'fn' and 'index'
    # (index 0, delete zero, add in two '')
    args.splice 0, 0, '', ''

    # when doing the remove action on a function it messes up the `for fn,index`
    # iteration loop.
    # So, i pulled index out separately, and, I use array length changes to
    # affect the index value. then it doesn't go up one when we just removed
    # a function. and, it would go up if we added one, tho, I don't have an
    # add action as part of select() stuff.

    # length at the start of the first operation, and, index starts at zero.
    length = chain.array.length
    index = 0

    # let's remember the results of each action
    results = []

    for fn in chain.array

      # apply the action to the function only if the selector say so
      if selector fn, index
        # put both of them in there as the first two args in the slots we created above
        args[0] = fn
        args[1] = index

        # call the action with the `chain` as the `this` and our args
        result = action.apply chain, args

        # compare length before the action and after the action
        diff = chain.array.length - length

        # apply the difference to the index.
        # when we remove one it's -1 so we reduce the index.
        index += diff

        # and then update the length
        length = chain.array.length

        # gather each action's results
        results.push result

      # we do the normal increment by one for the loop.
      # Note: this must happen every loop iteration
      index++

    # all done
    return result:true, results:results

  # create a selector function capable of selecting the desired member functions
  # and then apply the utility functions to them.
  #   selector = (fn, index) -> blah
  #   chain.select(selector).disable('reason')
  #   chain.select(selector).enable()
  #   chain.select(selector).remove()
  #   chain.select(selector).affect((fn, index, arg1, arg2, ...) -> blah)
  #
  # Note: if you want to affect a single function based its index, its id
  # or itself, then use the utility functions directly
  # like: chain.remove(2), chain.disable(fn, 'reason'), chain.enable('someid')
  select: (selector) ->

    # ensure the selector is a function
    unless typeof selector is 'function'

      # create an error about this problem
      error =
        error   : 'Selector must be an index, id, or filter function'
        selector: selector

      # create a function which returns the error
      returnError = -> error

      # return the error as part of this object, and, in case they don't check
      # for it, return the expected properties which call the function which
      # provides the error result.
      return ops =
        selector: selector
        error  : error.error
        disable: returnError
        enable : returnError
        remove : returnError
        affect : returnError

    # alias for below
    chain = this

    # return specially bound functions
    return ops =
      disable: @_actor.bind chain, selector, chain._disable
      enable : @_actor.bind chain, selector, chain._enable
      remove : @_actor.bind chain, selector, chain._remove
      # this one allows them to specify the action function to affect(...)
      affect : @_actor.bind chain, selector#, affector is the action


  # main function which begins the execution of the chain
  # optionally configure `context`, `done`, and `_buildContext`
  run: (options, done) ->

    if @_disabled? # if we're disabled then tell them
      return result:false, reason:'chain disabled', disabled:@_disabled

    ctx = @_buildContext options                   # build/use context
    done = options?.done ? done                    # look for `done`
    control = new Control this, @array, ctx, done  # create Control
    @emit 'start', control:control, chain:this     # notify we're starting
    result = control._execute()                    # start the chain
    if control.paused?                             # a paused chain isn't done
      results = paused:control.paused              # return only paused info
    else                                           # we're done, synch'ly
      results = @_finish result, control           # include available info
    return results                                 # return results, synch'ly


  # builds the final `results`, calls `done`, and emits 'done'
  _finish: (result, control) ->

    # store it all together. `result` could be true/false or an object
    results = result:result, context:control._context, chain:this

    # if they called control.stop() or control.fail() then include that info
    results.stopped = control.stopped if control.stopped?
    results.failed  = control.failed  if control.failed?
    # also include functions removed during this execution run by `control`
    results.removed = control.removed if control.removed?

    # call the done function if one exists
    error = result.error ? results.failed
    control._done? error, results

    # emit done with the same info
    @emit 'done', error, results

    # pass back the `results` we built
    return results


  # allows users to override how a context is built by changing this function.
  # also, this defualt implementation accepts a base object (prototype) to use
  # when creating a new context object, and a property descriptor
  _buildContext: (options) ->
    # if they specified a context to use, then use it
    if options?.context? then options.context

    # otherwise, build a new context.
    # use their specified prototype or an empty object,
    # and a property descriptor (if specified)
    else
      # get the base:
      #  1. from options which overrides everything
      #  2. from the chain's options
      #  3. the default is an empty object
      base = options?.base ? @_base ? {}

      # don't default to anything. Only use what's provided.
      props = options?.props ? @_props

      # now create with those
      Object.create base, props
