
flatten = require 'array-flatten'

module.exports = (args...) ->

  arg1 = args?[0]

  array =
    # buildChain([ someFn, someFn2 ], [moreFns, moreFns2])
    if Array.isArray arg1 then flatten args

    # buildChain(someFn, someFn2)
    else if typeof arg1 is 'function' then args

    # buildChain({ array:[ someFn, someFn2 ] })
    else if Array.isArray arg1?.array then arg1.array

    # otherwise start with an empty
    else []

  # validate array's contents: must be functions
  for element, index in array
    unless 'function' is typeof(element)
      return error:'Elements must be functions', element:element, index:index

  # we have the array so, put those in an options object.
  # mark we validated the array
  options = array:array, __validated:true

  # if we were provided an options object to start,
  # then select properties we care about, only if they exist.
  if typeof arg1 is 'object'
    options.base  = arg1.base if arg1?.base?
    options.props = arg1.props if arg1?.props?
    options.buildContext = arg1.buildContext if arg1?.buildContext?

  return options
