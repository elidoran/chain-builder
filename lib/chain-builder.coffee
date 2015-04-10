
Had = require 'had'

# TODO:
#  1. `had` support reporting status from within fn's? control ones and theirs
#  2. provide chain 'handle' on returned chain fn which can tell a chain to
#     stop (when it next checks the value...)


module.exports = builder =                   # export singleton object

  _checkArray: (had, propName, array) ->     # shared verification fn

    if had.nullArg 'array', array            # check if array is null
      return had.results()                   # return null arg error

    if array?[0]?.push?                      # splat causes wrapped array
      array = array[0]                       # unwrap array

    unless array?.length > 0                 # avoid work for empty array
      success = {}                           # create object to put prop on
      success[propName] = -> had.success()   # use specified name to hold noop
      return had.success success             # noop fn returns success

    for fn,i in array                        # loop over array, fn and index
      if typeof fn isnt 'function'           # ensure it's a function
        return had.error                     # add error properties
          error : 'not a function'           # required, is a message
          type  : 'typeof'                   # type the error for your handling
          name  : 'fn'                       # name of offending thing
          on    : fn                         # what object was the error on
          in    : array                      # what object was that in
          index : i                          # for array, what is its index
          during: 'array content validation' # what were we trying to do?

    array = array[..]                        # clone array

    return had.success array:array           # return success with array

  chain: (array...) ->                       # build chain over array

    had = Had id:'chain'                     # create our own had, name it

    result =                                 # verify array, clone it, shortcut
      builder._checkArray had, 'chain', array # needs name of prop to store fn

    if result?.error? or result?.chain?      # error or shortcut(fn), return it
      return result                          # as is

    else                                     # else it's a success, ready for us
      array = result.array                   # get the array (cloned)

    fn = (context={}) ->                      # return new function, the chain
      for fn,i in array                       # loop over provided functions
        result = do (fn) ->                   # run in own scope, hold return result
          itsThis = fn?.options?.this ? context # choose the *this* context
          try                                 # grab errors in chain calls
            return fn.call itsThis, context   # calls function with context=itsThis
          catch e
            return had.error                  # add error properties
              error: 'chain function threw error' # required, is a message
              type : 'caught'                 # type the error for your handling
              name : 'fn'                     # name of offending thing
              on   : fn                       # what object was the error on
              in   : array                    # what object was that in
              index: i                        # for array, what is its index
              Error:e                         # store Error in error info

        # the chained function might return a 'had' error/result
        # so, use that if so.
        unless had.isSuccess result           # test for success/error
          if result?.error? then return result# return had error as is
          else return had.error               # create an error to return
            error:'received false'            # tell we received a false
            type: 'chaining'                  # what's going on

      return had.success()                    # successful chain, return success

    return had.success chain:fn               # return success with generated fn

  pipeline: (array...) ->                     # build pipeline over array

    had = Had id:'pipeline'                   # create our own had, name it

    result =                                 # verify array, clone it, shortcut
      builder._checkArray had, 'pipeline', array # needs name of prop to store fn

    if result?.error? or result?.pipeline?   # error or shortcut(fn), return it
      return result                          # as is

    else                                     # else it's a success, ready for us
      array = result.array                   # get the array (cloned)

    fn = (ctx={}) ->                          # return new function, pipeline
      i = 0                                   # start with first fn in array
      caller = (next, context) ->             # new fn calls their fn
        fn = array[i]                         # get next function to call
        itsThis = fn?.options?.this ? context # choose the *this* context
        try                                   # catch errors from call
          return fn.call itsThis, next, context # call: context=itsThis
        catch e
          return had.error                  # add error properties
            error: 'chain function threw error' # required, is a message
            type : 'caught'                 # type the error for your handling
            name : 'fn'                     # name of offending thing
            on   : fn                       # what object was the error on
            in   : array                    # what object was that in
            index: i                        # for array, what is its index
            Error:e

      repeater = (context=ctx) ->             # the 'next' function
        i++                                   # advance 'i'
        if i < array.length                   # check there is another fn
          return caller repeater, context     # call it with context+next
        else
          return true                         # successful pipeline, return true

      result = caller repeater, ctx           # initiate pipeline, return result

      # TODO: had should help with this mess :)
      if result is true                       # just true (common result)
        return had.success()                  # return basic success result

      else if result is false                 # just false (common stopper)
        return had.error                      # return an error result
          error:'received false'              # tell we received a false
          type:'chaining'                     # what's going on

      else if result?.error? or result?.success? # had result instead of boolean
        return result                         # return it as is

    return had.success pipeline:fn            # return success with generated fn
