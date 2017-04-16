getOptions = require './get-options'
Chain = require './chain'

module.exports = ->

  # optimization friendly method
  args = new Array arguments.length
  args[i] = arguments[i] for i in [0...arguments.length]

  options = getOptions.apply null, args

  new Chain options

module.exports.Chain = Chain
module.exports.Control = require './control'
