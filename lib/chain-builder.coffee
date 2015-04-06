
### ######################
# Not yet supporting 'had'
### ######################
module.exports = builder =                    # export singleton object

  chain: (array) ->                           # build chain over array

    if array?.length > 0                      # avoid work for empty array
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

    else # TODO: warning?                     # empty array
      return -> true                          # noop func returns true
