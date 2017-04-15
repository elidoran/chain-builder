flatten    = require 'array-flatten'

buildChain = require '../lib/index'

benchmark  = require './benchmark'
benchmarks = require './benchmarks'


basicSetup = (buildOptions, runOptions) ->   ->
  if buildOptions?.array?
    buildOptions.array = flatten buildOptions.array
  @setup =
    chain: buildChain buildOptions
    runOptions: runOptions
  return

runChain = (repeat) ->
  {chain, runOptions} = @setup
  chain.run runOptions for i in [0 ... repeat]
  return

functions = require './functions'

benchmarks = benchmarks [

  benchmark 'run() empty',
    setup: basicSetup()
    run  : runChain


  benchmark 'run() single',
    setup: basicSetup array:[ functions.empty ]
    run  : runChain


  benchmark 'run() many',
    setup: basicSetup array:[ functions.repeat 101, functions.empty ]
    run  : runChain


  benchmark 'run() single inc, n is   defined',
    setup: basicSetup
      array:[ functions.increment ]
      buildContext: -> n: 0
    run  : runChain

  benchmark 'run() single inc, n is undefined',
    setup: basicSetup array:[ (-> @n = 0), functions.increment ]
    run  : runChain


  benchmark 'run() many   inc, n is   defined',
    setup: basicSetup
      array:[ functions.repeat 101, functions.increment ]
      buildContext: -> n: 0
    run  : runChain

  benchmark 'run() many   inc, n is undefined',
    setup: basicSetup
      array:[ (-> @n = 0), functions.repeat 101, functions.increment ]
    run  : runChain


  benchmark 'run() many   inc, n is   defined',
    setup: basicSetup
      array:[ functions.repeat 101, functions.incrementBy(12345) ]
      buildContext: -> n: 0
    run  : runChain

  benchmark 'run() many   inc, n is undefined',
    setup: basicSetup
      array:[ (-> @n = 0), functions.repeat 101, functions.incrementBy(12345) ]
    run  : runChain


  benchmark 'run() many   inc,  all   defined',
    setup: basicSetup
      array:[ functions.repeat 101, functions.incrementMany ]
      buildContext: -> a:0, b:0, c:0, d:0, e:0, f:0, g:0
    run  : runChain

  benchmark 'run() many   inc,  all undefined',
    setup: basicSetup
      array:[
        -> @a = 0 ; @b = 0 ; @c = 0 ; @d = 0 ; @e = 0 ; @f = 0 ; @g = 0
        functions.repeat 101, functions.incrementMany
      ]
    run  : runChain


  benchmark 'run() many   context temporary',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.context()
        functions.repeat(50, functions.empty)
      ]
      buildContext: -> a:0, b:0, c:0, d:0, e:0, f:0, g:0
    run  : runChain

  benchmark 'run() many   context permanent',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.contextPermanent()
        functions.repeat(50, functions.empty)
      ]
      buildContext: -> a:0, b:0, c:0, d:0, e:0, f:0, g:0
    run  : runChain


  benchmark 'run() many   next    temporary',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.next()
        functions.repeat(50, functions.empty)
      ]
      buildContext: -> a:0, b:0, c:0, d:0, e:0, f:0, g:0
    run  : runChain

  benchmark 'run() many   next    permanent',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.nextPermanent()
        functions.repeat(50, functions.empty)
      ]
      buildContext: -> a:0, b:0, c:0, d:0, e:0, f:0, g:0
    run  : runChain


  # add failed/paused/stopped stuff.
  # add disable/enable stuff.

]

repeat = do ->
  index = process.argv.indexOf '--repeat'
  if index > -1 and process.argv.length > index + 1
    Math.max 1, Number process.argv[index + 1]
  else 1

benchmarks.run
  old   : require './result.json'
  repeat: repeat
  report: '--report' in process.argv
  store : '--store' in process.argv
