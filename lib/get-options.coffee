flatten = require '@flatten/array'

# buildChain(someFn, someFn2)
# buildChain([ someFn, someFn2 ], [moreFns, moreFns2])
# buildChain({ array:[ someFn, someFn2 ] })
module.exports = () ->

  # optimization friendly method
  args = new Array arguments.length
  args[i] = arguments[i] for i in [0...arguments.length]

  # include any array args into the main array. one big happy array.
  args = flatten args

  # we either have an array of functions, or, an "options" object at [0]
  array = switch typeof args[0]

    # if the first arg is a function then we must not have received
    # an options object. So, use the array we already created.
    when 'function' then args

    # if it's an object then use the `array` property, or []
    when 'object'
      options = args[0]
      args[0].array ? []

    # otherwise, make a brand new empty array
    else []

  # validate array's contents: must be functions
  for element, index in array
    unless 'function' is typeof element
      return error:'Elements must be functions', element:element, index:index

  # # specify all the options properties
  # this is a marker telling the Chain constructor we've validated these
  __validated:true
  array: array
  base : options?.base
  props: options?.props
  buildContext: options?.buildContext
