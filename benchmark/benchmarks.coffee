chalk  = require 'chalk'
pad    = require 'pad'
format = require 'comma-number'

class Benchmarks

  constructor: (@benchmarks) ->

    @info = []

  run: (options) ->

    original = options.original
    repeat = options.repeat ? 1
    report = options.report is true
    store  = options.store is true

    console.log """
    run benchmarks
      repeat: #{format repeat}
      report: #{report}
      store : #{store}

    """

    if report then @reportHeader()

    # for each
    for benchmark, index in @benchmarks

      benchmark.setup()

      # pre-run for optimization
      benchmark.run Math.max 1, Math.floor repeat * 0.25 # TODO: support asynchronous ...

      start = process.hrtime()

      result = benchmark.run repeat # TODO: support asynchronous ...

      elapsed = process.hrtime start

      info = { benchmark, repeat, elapsed, result, original:original.info[index] }
      if report then @reportResult info
      if store  then @storeResult info

    # after all done...
    if store then @store()


  format: (length, string) -> pad length, @crop length, format string

  crop: (length, string) ->
    index = string.indexOf '.'
    if index < 0 then index = length
    else if index < 3 then index = 5
    string[0 ... index]

  reportHeader: ->
    h1 = chalk.blue pad(12, 'old rate')
    h2 = ' |' + chalk.blue pad 12, 'new rate'
    h3 = ' |' + pad 10, 'change'
    h4 = ' |' + chalk.magenta pad 12, 'old secs'
    h5 = ' |' + chalk.magenta pad 12, 'new secs'
    h6 = ' |' + chalk.bold ' label'
    console.log h1 + h2 + h3 + h4 + h5 + h6
    console.log '--------------------------------------------------------------------'

  reportResult: ({benchmark, repeat, elapsed, original}) ->

    originalSecs = original.seconds + (original.nanos / 1e9)
    newSecs      = elapsed[0] + (elapsed[1] / 1e9)

    originalRate = original.repeat / originalSecs
    newRate      = repeat / newSecs

    secs0 = chalk.magenta @format 12, originalSecs
    rate0 = chalk.blue @format 12, originalRate

    secs1 = chalk.magenta @format 12, newSecs
    rate1 = chalk.blue @format 12, newRate

    change = Math.round(((newRate - originalRate) / originalRate) * 100)
    color =
      if change > 0.01 then chalk.green
      else if change < -0.01 then chalk.red
      else chalk.black
    change = color(@format 9, change.toFixed 0) + '%'

    label = chalk.bold benchmark.label


    line = rate0 + ' |' + rate1 + ' |' + change + ' |' + secs0 + ' |' + secs1 + ' |  ' + label
    console.log line


  storeResult: ({benchmark, repeat, elapsed}) ->
    @info[@info.length] =
      label: benchmark.label
      repeat: repeat
      seconds: elapsed[0]
      nanos: elapsed[1]

  store: () ->

    console.log 'storing benchmark results...'
    path = require('path').resolve __dirname, 'result.json'
    content = JSON.stringify {@info}, null, 2
    require('fs').writeFile path, content, 'utf8', (error) ->
      if error? then return console.error error
      console.log 'stored benchmark results to result.json'


module.exports = (benchmarks) -> new Benchmarks benchmarks
