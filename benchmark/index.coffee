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
    run  : runChain

  benchmark 'run() many   context permanent',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.contextPermanent()
        functions.repeat(50, functions.empty)
      ]
    run  : runChain


  benchmark 'run() many   next    temporary',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.next()
        functions.repeat(50, functions.empty)
      ]
    run  : runChain

  benchmark 'run() many   next    permanent',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.nextPermanent()
        functions.repeat(50, functions.empty)
      ]
    run  : runChain


  benchmark 'run() many   fail',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.fail()
        functions.repeat(50, functions.empty)
      ]
    run  : runChain

  benchmark 'run() many   fail',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.fail 'testing'
        functions.repeat(50, functions.empty)
      ]
    run  : runChain


  benchmark 'run() many   stop',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.stop()
        functions.repeat(50, functions.empty)
      ]
    run  : runChain

  benchmark 'run() many   stop',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.stop  'testing'
        functions.repeat(50, functions.empty)
      ]
    run  : runChain

  #
  # TODO:
  #
  # support async so we can call resume()
  benchmark 'run() many   pause',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.pause()
        functions.repeat(50, functions.empty)
      ]
    run  : runChain

  benchmark 'run() many   pause',
    setup: basicSetup
      array:[
        functions.repeat(50, functions.empty)
        functions.pause  'testing'
        functions.repeat(50, functions.empty)
      ]
    run  : runChain


  # add disable/enable stuff.
  benchmark 'run() many   disabled chain',
    run  : runChain
    setup: ->
      chain = buildChain array: flatten [
        functions.repeat(101, functions.empty)
      ]
      chain.disable()
      @setup = chain: chain#, runOptions: null
      return

  benchmark 'run() many   disabled chain    w/reason',
    run  : runChain
    setup: ->
      chain = buildChain array: flatten [
        functions.repeat(101, functions.empty)
      ]
      chain.disable 'testing'
      @setup = chain: chain#, runOptions: null
      return


  benchmark 'run() many   disabled function w/reason',
    run  : runChain
    setup: ->
      id = 'target'
      @setup =
        chain: buildChain array: flatten [
          functions.repeat(50, functions.empty)
          functions.id(id)
          functions.repeat(50, functions.empty)
        ]
      @setup.chain.disable id, 'testing'
      return


  benchmark 'select() disable none',
    setup: -> @setup =
      selector: (fn, index) -> false
      chain   : buildChain array: functions.repeat(101, functions.empty)

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).disable()

  benchmark 'select() disable none     w/reason',
    setup: -> @setup =
      selector: (fn, index) -> false
      chain   : buildChain array: functions.repeat(101, functions.empty)

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).disable 'testing'


  benchmark 'select() disable single',
    setup: -> @setup =
      selector: (fn, index) -> index is 50 # if fn.options?.id is 'target'
      chain   : buildChain array: flatten [
        functions.repeat(50, functions.empty)
        functions.id 'target'
        functions.repeat(50, functions.empty)
      ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).disable()

  benchmark 'select() disable single   w/reason',
    setup: -> @setup =
      selector: (fn, index) -> index is 50 # if fn.options?.id is 'target'
      chain   : buildChain array: flatten [
        functions.repeat(50, functions.empty)
        functions.id 'target'
        functions.repeat(50, functions.empty)
      ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).disable 'testing'


  benchmark 'select() disable multiple',
    setup: ->
      options = select: true
      @setup =
        selector: (fn) -> fn.options?.select is true
        chain   : buildChain array: flatten [
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
        ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).disable()

  benchmark 'select() disable multiple w/reason',
    setup: ->
      options = select: true
      @setup =
        selector: (fn) -> fn.options?.select is true
        chain   : buildChain array: flatten [
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
        ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).disable 'testing'



  benchmark 'select() enable  none',
    setup: -> @setup =
      selector: (fn, index) -> false
      chain   : buildChain array: functions.repeat(101, functions.empty)

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).enable()

  benchmark 'select() enable  none     w/reason',
    setup: -> @setup =
      selector: (fn, index) -> false
      chain   : buildChain array: functions.repeat(101, functions.empty)

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).enable 'testing'


  benchmark 'select() enable  single',
    setup: -> @setup =
      selector: (fn, index) -> index is 50 # if fn.options?.id is 'target'
      chain   : buildChain array: flatten [
        functions.repeat(50, functions.empty)
        functions.options id:'target', disabled:true
        functions.repeat(50, functions.empty)
      ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).enable()

  benchmark 'select() enable  single   w/reason',
    setup: -> @setup =
      selector: (fn, index) -> index is 50 # if fn.options?.id is 'target'
      chain   : buildChain array: flatten [
        functions.repeat(50, functions.empty)
        functions.options id:'target', disabled:true
        functions.repeat(50, functions.empty)
      ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).enable 'testing'


  benchmark 'select() enable  multiple',
    setup: ->
      options = select: true, disabled: true
      @setup =
        selector: (fn) -> fn.options?.select is true
        chain   : buildChain array: flatten [
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
        ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).enable()

  benchmark 'select() enable  multiple w/reason',
    setup: ->
      options = select: true, disabled: true
      @setup =
        selector: (fn) -> fn.options?.select is true
        chain   : buildChain array: flatten [
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
        ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).enable 'testing'



  benchmark 'select() remove  none',
    setup: -> @setup =
      selector: (fn, index) -> false
      chain   : buildChain array: functions.repeat(101, functions.empty)

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).remove()

  benchmark 'select() remove  none     w/reason',
    setup: -> @setup =
      selector: (fn, index) -> false
      chain   : buildChain array: functions.repeat(101, functions.empty)

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).remove 'testing'


  benchmark 'select() remove  single',
    setup: -> @setup =
      selector: (fn, index) -> index is 50 # if fn.options?.id is 'target'
      chain   : buildChain array: flatten [
        functions.repeat(50, functions.empty)
        functions.id 'target'
        functions.repeat(50, functions.empty)
      ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).remove()

  benchmark 'select() remove  single   w/reason',
    setup: -> @setup =
      selector: (fn, index) -> index is 50 # if fn.options?.id is 'target'
      chain   : buildChain array: flatten [
        functions.repeat(50, functions.empty)
        functions.id 'target'
        functions.repeat(50, functions.empty)
      ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).remove 'testing'


  benchmark 'select() remove  multiple',
    setup: ->
      options = select: true
      @setup =
        selector: (fn, index) ->
          fn.options?.select is true
        chain   : buildChain array: flatten [
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.empty
        ]
      return

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).remove()

  benchmark 'select() remove  multiple w/reason',
    setup: ->
      options = select: true
      @setup =
        selector: (fn) -> fn.options?.select is true
        chain   : buildChain array: flatten [
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.empty
        ]

    run  : (repeat) ->
      {chain, selector} = @setup
      chain.select(selector).remove 'testing'



  benchmark 'select() affect  none',
    setup: -> @setup =
      chain   : buildChain array: functions.repeat(101, functions.empty)
      selector: (fn, index) -> false
      action  : (fn, index, arg1, arg2) ->
        if arg1 isnt 'arg1' then console.log 'arg1 mismatch:',arg1
        if arg2 isnt 'arg2' then console.log 'arg2 mismatch:',arg2

    run  : (repeat) ->
      {chain, selector, action} = @setup
      chain.select(selector).affect selector, action, 'arg1', 'arg2'


  benchmark 'select() affect  single',
    setup: -> @setup =
      selector: (fn, index) -> fn.options?.select is true
      action  : (fn, index, arg1, arg2) ->
        if arg1 isnt 'arg1' then console.log 'arg1 mismatch:',arg1
        if arg2 isnt 'arg2' then console.log 'arg2 mismatch:',arg2
        fn.options.args = [arg1, arg2]

      chain   : buildChain array: flatten [
        functions.repeat(50, functions.empty)
        functions.options id:'target', select:true
        functions.repeat(50, functions.empty)
      ]

    run  : (repeat) ->
      {chain, selector, action} = @setup
      chain.select(selector).affect selector, action, 'arg1', 'arg2'


  benchmark 'select() affect  multiple',
    setup: ->
      options = select: true
      @setup =
        selector: (fn, index) -> fn.options?.select is true
        action  : (fn, index, arg1, arg2) ->
          if arg1 isnt 'arg1' then console.log 'arg1 mismatch:',arg1
          if arg2 isnt 'arg2' then console.log 'arg2 mismatch:',arg2
          fn.options.args = [arg1, arg2]
        chain   : buildChain array: flatten [
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.repeat(10, functions.empty)
          functions.options options
          functions.empty
        ]
      return

    run: (repeat) ->
      {chain, selector, action} = @setup
      chain.select(selector).affect selector, action, 'arg1', 'arg2'


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
