
module.exports = builder =

  chain: (array) ->

    if array?.length > 0
      return (context) ->
        for fn in array
          okay = do (fn) ->
            try
              return fn context, control
            catch e
              console.log 'error in chain: ', e
              return false

          unless okay?
            break

    else # TODO: warning?
      return ->
