
### #################### ###
# Not yet supporting 'had' #
### #################### ###

# TODO:
#  1. `had` support reporting status from within fn's? control ones and theirs
#  2. provide chain 'handle' on returned chain fn which can tell a chain to
#     stop (when it next checks the value...)


module.exports = builder =                    # export singleton object

  chain: (array) ->                           # build chain over array

    unless array?                             # null/undefined ?
      # TODO: use had to respond with error   # use `had` instead
      throw new Error 'null array param'      # throw error,

    if typeof array is 'function'             # single argument can be function
      array = [array]                         # so wrap it in an array

    if array?.length > 0                      # avoid work for empty array

      array = array[..]                       # clone array

      do (array) ->                             # check array contents
        for fn,i in array # TODO: use `had`     # loop over array, fn and index
          if typeof fn isnt 'function'          # ensure it's a function
            err = "[#{i}] not a function: #{fn}"# include index and value
            throw new Error err                 # throw it (TODO: use `had`)

      return (context) ->                     # return new function, the chain
        for fn in array                       # loop over provided functions
          okay = do (fn) ->                   # run in own scope, hold return result
            try                               # grab errors in chain calls
              return fn context               # calls function, return result
            catch e
              console.log 'chain: error', e   # report to console. TODO: remove?
              context.chainError = e          # store error in context
              return false                    # end chain with false return

          if not okay then return false       # stop chain loop when false

        return true                           # successful chain, return true

    else # TODO: warning? had'd warn          # empty array
      return -> true                          # noop fn returns true


  pipeline: (array) ->                        # build pipeline over array

    unless array?                             # null/undefined ?
      # TODO: use had to respond with error   # use `had` instead
      throw new Error 'null array param'      # throw error,

    if typeof array is 'function'             # single argument can be function
      array = [array]                         # so wrap it in an array

    unless array?.length > 0                  # avoid work for empty array
      # TODO: warning. had'd warn
      return -> return true                   # noop fn returns true

    array = array[..]                         # clone array

    do (array) ->                             # check array contents
      for fn,i in array # TODO: use `had`     # loop over array, fn and index
        if typeof fn isnt 'function'          # ensure it's a function
          err = "[#{i}] not a function: #{fn}"# include index and value
          throw new Error err                 # throw it (TODO: use `had`)

    return (context) ->                       # return new function, pipeline
      i = 0                                   # start with first fn in array
      caller = (context, next) ->             # new fn calls their fn
        fn = array[i]                         # get next function
        if fn?                                # if it exists TODO: check type?
          fn context, next                    # call with provided args
        else return false                     # send false up the pipeline

      repeater = (context) ->                 # the 'next' function
        i++                                   # advance 'i'
        if i < array.length                   # check there is another fn
          caller context, repeater            # call it with context+next
        else true                             # successful pipeline, return true

      return caller context, repeater         # initiate pipeline, return result
