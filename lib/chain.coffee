Control = require './control'

###
  Chain holds an array of functions to execute in sequence managed by a Control.
###
module.exports = class Chain extends require('events').EventEmitter

  constructor: (options) ->

    # if module's builder function already validated the array then use it
    # and avoid redoing that same work
    if options?.__validated
      array = options.array

    # otherwise, let's be safe, must find the array and validate it
    else
      array =
        if Array.isArray options then options                    # new Chain [...]
        else if typeof options is 'function' then [ options ]    # new Chain fn
        else if Array.isArray options?.array then options.array  # new Chain array:[]
        else []                                                  # new Chain()

      # validate array's contents: must be functions
      for element,index in array
        unless 'function' is typeof(element)
          # can't return a value from constructor, so, throw Error
          throw new Error 'Elements must be functions. Invalid #'+index+':'+element

    # an array of functions, so simple, until you wrap a Chain around it...
    @array = array

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
      unless 'function' is typeof(fn) then return error:'must be a function',fn:fn

    # append them into the array via splice()
    @array.splice @array.length, 0, fns...

    # if length is different then we actually added some, so emit 'add'
    # Note: this exists because it's possible to call add with nothing and
    # it would still emit an 'add' event despite not adding anything
    if length isnt @array.length then @emit 'add', fns

    # it's all good
    return success:true

  # remove function from the array via: index, id, or itself
  #  chain.remove 3
  #  chain.remove 'some-id'
  #  chain.remove fn1
  remove: (selector) ->

    switch typeof selector

      # a string must be an id of one of the functions, so find it
      when 'string'

        # return -1 unless we find it
        index = -1

        for fn,i in @array
          if selector is fn?.options?.id
            index = i
            break

      # if they provided the index to use...
      when 'number' then index = selector

      # find the function in the array
      when 'function' then index = @array.indexOf selector

      # woh! no good
      else return error:'Remove requires an ID, an index, or a function.', remove:selector

    # by default, return an empty object because we didn't remove anything
    result = {}

    # if we found it tho
    if index > -1
      # then remove it from the array and assign it into the result
      result.removed = @array.splice index, 1

      # let everyone know we removed it
      @emit 'remove', result.removed

    # and return the result whether it's empty or not
    return result

  # empty the chain of all functions and let everyone know
  clear: ->
    if @array.length > 0      # only operate when there's some content
      array = @array          # remember the array
      @array = []             # new empty array = clear
      @emit 'remove', array   # emit a remove event with the array

  # main function which begins the execution of the chain
  # options optionally configures `context`, `done`, and `_buildContext`
  run: (options, done) ->
    context = @_buildContext options               # build/use context
    done = options?.done ? done                    # look for `done`
    control = new Control @, @array, context, done # create controller
    @emit 'start', control:control, chain:this     # notify we're starting
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

  # allows users to override how a context is built by changing this function.
  # also, this defualt implementation accepts a base object (prototype) to use
  # when creating a new context object, and a property descriptor
  _buildContext: (options) ->
    # if they specified a context to use, then use it
    if options?.context? then options.context

    # otherwise, build a new context.
    # use their specified prototype or an empty object,
    # and a property descriptor (if specified)
    else Object.create options?.base ? {}, options?.props
