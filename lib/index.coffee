
getOptions = require './get-options'
Chain = require './chain'

module.exports = (args...) ->

  options = getOptions args...

  new Chain options

module.exports.Chain = Chain
module.exports.Control = require './control'
