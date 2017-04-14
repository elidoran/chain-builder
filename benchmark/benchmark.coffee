class Benchmark

  constructor: (@label, options) ->

    #
    @setup = options.setup ? ->
    @run   = options.run




module.exports = (label, options) -> new Benchmark label, options
