
Control = require './control'

module.exports = class Chain extends require('events').EventEmitter

  constructor: (options) ->

    # if module's builder function already validated the array then use it
    if options?.__validated
      array = options.array

    # must find the array and validate it
    else
      array =
        if Array.isArray options then options
        else if typeof options is 'function' then [ options ]
        else if Array.isArray options?.array then options.array
        else []

      # validate array's contents: must be functions
      for element,index in array
        unless 'function' is typeof(element)
          # can't return a value from constructor, so, throw Error
          throw new Error 'Elements must be functions. Invalid #'+index+':'+element

    @array = array

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
