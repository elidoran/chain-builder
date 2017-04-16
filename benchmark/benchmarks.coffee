chalk  = require 'chalk'
pad    = require 'pad'
format = require 'comma-number'

SEP = /[,\.]/

class Benchmarks

  constructor: (@benchmarks) ->

    @info = []

  run: (options) ->

    old    = options.old
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
      prerun = if repeat is 1 then 1 else Math.max 100, Math.floor repeat * 0.25
      benchmark.run prerun # TODO: support asynchronous ...

      start = process.hrtime()

      result = benchmark.run repeat # TODO: support asynchronous ...

      elapsed = process.hrtime start

      info = { benchmark, repeat, elapsed, result, old:old.info[index] }
      if report then @reportResult info
      if store  then @storeResult info

    # after all done...
    if store then @store()


  format: (length, num) -> pad length, @crop length, num, format num

  crop: (length, num, string) ->

    match = SEP.exec string

    if match?

      if match[0] is ','
        string = string[0 ... match.index] + '.' + string[match.index + 1]
        string +=
          switch
            when num < 1e6 then ' G'
            when num < 1e9 then ' M'
            when num < 1e12 then ' B'
            when num < 1e15 then ' T'
            when num < 1e18 then ' P'
            else ' !'

      else string[0..5]

    else string[0...length]


  reportHeader: ->
    padSize = 10
    h1 = chalk.blue pad padSize, 'old ops/s'
    h2 = ' |' + chalk.blue pad padSize, 'new ops/s'
    h3 = ' |' + pad padSize - 1, 'change'
    h4 = ' |' + chalk.magenta pad padSize, ' old secs'
    h5 = ' |' + chalk.magenta pad padSize, ' new secs'
    h6 = ' |' + chalk.bold ' label'
    console.log h1 + h2 + h3 + h4 + h5 + h6
    console.log '----------------------------------------------------------------------------------------------'

  reportResult: (info) ->
    # info = {benchmark, repeat, elapsed, old}
    padSize = 10

    if info.old?
      oldTimeNum = info.old.seconds + (info.old.nanos / 1e9)
      oldTime    = chalk.magenta @format padSize, oldTimeNum
      oldRateNum = info.old.repeat / oldTimeNum
      oldRate    = chalk.blue @format padSize, oldRateNum

    else
      oldTime = '         N/A'
      oldRate = '         N/A'

    newTimeNum = info.elapsed[0] + (info.elapsed[1] / 1e9)
    newTime    = chalk.magenta @format padSize, newTimeNum
    newRateNum = info.repeat / newTimeNum
    newRate    = chalk.blue @format padSize, newRateNum

    if info.old?
      change = Math.round(((newRateNum - oldRateNum) / oldRateNum) * 100)
      color =
        if change > 0.01 then chalk.green
        else if change < -0.01 then chalk.red
        else chalk.black
      change = color(@format padSize - 2, change.toFixed 0)

    else change = pad padSize - 2, 'N/A '

    label = chalk.bold info.benchmark.label

    console.log """
    #{oldRate} |#{newRate} |#{change}% |#{oldTime} |#{newTime} |  #{label}
    """


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
