
Chain = require './chain'

module.exports = (options) ->

  array =
    if Array.isArray options then options
    else if typeof options is 'function' then [ options ]
    else if Array.isArray options?.array then options.array
    else []

  # validate array's contents: must be functions
  for element,index in array
    unless 'function' is typeof(element)
      return error:'Elements must be functions', element:element, index:index

  new Chain array:array, __validated:true

module.exports.Chain = Chain
module.exports.Control = require './control'
