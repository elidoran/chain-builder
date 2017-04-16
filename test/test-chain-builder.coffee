assert = require 'assert'
buildChain = require '../lib'

# 1. build chain
describe 'test building chain', ->

  it 'without options should build chain w/out fn\'s', ->
    chain = buildChain()
    assert chain, 'should return the chain'
    assert chain.array, 'should have an array'
    assert.equal chain?.array?.length, 0, 'should have an empty array'

  it 'with empty options should build chain w/out fn\'s', ->
    chain = buildChain {}
    assert chain, 'should return the chain'
    assert chain.array, 'should have an array'
    assert.equal chain?.array?.length, 0, 'should have an empty array'

  it 'with empty array in options should build chain w/out fn\'s', ->
    chain = buildChain array:[]
    assert chain, 'should return the chain'
    assert chain.array, 'should have an array'
    assert.equal chain?.array?.length, 0, 'should have an empty array'

  it 'with array in options should build chain w/one fn', ->
    fn = ->
    chain = buildChain array:[fn]
    assert chain, 'should return the chain'
    assert chain.array, 'should have an array'
    assert.equal chain?.array?.length, 1, 'should have fn in array'
    assert.strictEqual chain.array[0], fn


# 2. chain.add()
describe 'test chain.add()', ->

  chain = null
  fn1 = ->
  fn2 = ->
  fn3 = ->
  beforeEach ->
    chain = buildChain()

  it 'should add single fn to array', ->
    chain.add fn1
    assert.equal chain.array.length, 1, 'array should have one element'
    assert.strictEqual chain.array[0], fn1, 'array should contain fn'

  it 'should add multiple fn\'s, individually, to array', ->
    array = [fn1, fn2, fn3]
    chain.add fn for fn in array
    assert.equal chain.array.length, 3, 'array should have one element'
    assert.deepEqual chain.array, array, 'array should contain fn\'s'

  it 'should add multiple fn\'s, via splat, to array', ->
    chain.add fn1, fn2, fn3
    assert.equal chain.array.length, 3, 'array should have one element'
    assert.strictEqual chain.array[0], fn1, 'array should contain fn'
    assert.strictEqual chain.array[1], fn2, 'array should contain fn2'
    assert.strictEqual chain.array[2], fn3, 'array should contain fn3'

  it 'should add multiple fn\'s, via an array, to array', ->
    chain.add [fn1, fn2, fn3]
    assert.equal chain.array.length, 3, 'array should have one element'
    assert.strictEqual chain.array[0], fn1, 'array should contain fn'
    assert.strictEqual chain.array[1], fn2, 'array should contain fn2'
    assert.strictEqual chain.array[2], fn3, 'array should contain fn3'

  it 'should return error when an arg/element is not a function', ->
    arg = 'string'
    result = chain.add arg
    assert result, 'should return a result'
    assert.equal result.error, 'must be a function'
    assert.strictEqual result.fn, arg

  it 'should return error when an arg/element is not a function', ->
    arg = some:'object'
    result = chain.add arg
    assert result, 'should return a result'
    assert.equal result.error, 'must be a function'
    assert.strictEqual result.fn, arg

  it 'should return error when an arg/element is not a function', ->
    arg = 123
    result = chain.add arg
    assert result, 'should return a result'
    assert.equal result.error, 'must be a function'
    assert.strictEqual result.fn, arg


# 3. remove
# - chain.remove(index)
# - chain.remove('someid', 'reason')
# - chain.remove('someid')
# - chain.remove('someid', 'reason')
# - chain.remove(someFn)
# - chain.remove(someFn, 'reason')
#
# - control.remove()
# - control.remove('reason')
#
# - chain.select(fn).remove()
# - chain.select(fn).remove('reason')

describe 'test chain.remove()', ->
  fn1 = ->
  fn1.options = id:'fn1'
  fn2 = ->
  fn2.options = id:'fn2'
  fn3 = ->
  fn3.options = id:'fn3'

  chain = null

  beforeEach ->
    chain = buildChain()
    chain.add fn1

  it 'should return an error when chain is empty', ->
    chain.array = []
    result = chain.remove 0
    assert.equal result.error, 'Invalid index: 0'

  it 'should return a false result when id isnt found', ->
    chain.array = []
    result = chain.remove 'id'
    assert.equal result.result, false
    assert.equal result.reason, 'not found'

  it 'should return a false result when fn isnt found', ->
    chain.array = []
    result = chain.remove fn1
    assert.equal result.result, false
    assert.equal result.reason, 'not found'


  it 'should remove fn1 from array by index', ->
    result = chain.remove 0
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by index with reason', ->
    reason = 'the reason'
    result = chain.remove 0, reason
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.equal result.removed.length, 1, 'should remove one function'
    assert.equal result.reason, reason
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by index', ->
    chain.add fn2, fn3
    result = chain.remove 0
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn2, 'first element should be fn2'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn2 from array by index with reason', ->
    reason = 'the reason'
    result = chain.add fn2, fn3
    result = chain.remove 'fn2', reason
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.equal result.reason, reason
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed?[0], fn2


  it 'should remove fn1 from array by ID (single)', ->
    result = chain.remove 'fn1'
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by ID (single) with reason', ->
    reason = 'the reason'
    result = chain.remove 'fn1', reason
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.equal result.reason, reason
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by ID (multiple)', ->
    chain.add fn2, fn3
    result = chain.remove 'fn1'
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn2, 'first element should be fn2'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by ID (multiple) with reason', ->
    chain.add fn2, fn3
    reason = 'the reason'
    result = chain.remove 'fn1', reason
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.equal result.reason, reason
    assert.strictEqual chain.array[0], fn2, 'first element should be fn2'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn2 from array by ID (multiple)', ->
    chain.add fn2, fn3
    result = chain.remove 'fn2'
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed?[0], fn2

  it 'should remove fn2 from array by ID (multiple) with reason', ->
    reason = 'the reason'
    chain.add fn2, fn3
    result = chain.remove 'fn2', reason
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.equal result.reason, reason
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed?[0], fn2

  it 'should remove fn3 from array by ID (multiple)', ->
    chain.add fn2, fn3
    result = chain.remove 'fn3'
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn2, 'second element should be fn2'
    assert.strictEqual result.removed?[0], fn3

  it 'should remove fn3 from array by ID (multiple) with reason', ->
    reason = 'the reason'
    chain.add fn2, fn3
    result = chain.remove 'fn3', reason
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.equal result.reason, reason
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn2, 'second element should be fn2'
    assert.strictEqual result.removed?[0], fn3



  it 'should remove fn1 from array by itself (single)', ->
    result = chain.remove fn1
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by itself (single) with reason', ->
    reason = 'the reason'
    result = chain.remove fn1, reason
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.equal result.reason, reason
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by itself (multiple)', ->
    chain.add fn2, fn3
    result = chain.remove fn1
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn2, 'first element should be fn2'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn1 from array by itself (multiple) with reason', ->
    reason = 'the reason'
    chain.add fn2, fn3
    result = chain.remove fn1, reason
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.equal result.reason, reason
    assert.strictEqual chain.array[0], fn2, 'first element should be fn2'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove fn2 from array by itself (multiple)', ->
    chain.add fn2, fn3
    result = chain.remove fn2
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn2

  it 'should remove fn2 from array by itself (multiple) with reason', ->
    reason = 'the reason'
    chain.add fn2, fn3
    result = chain.remove fn2, reason
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.equal result.reason, reason
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn3, 'second element should be fn3'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn2

  it 'should remove fn3 from array by itself (multiple)', ->
    chain.add fn2, fn3
    result = chain.remove fn3
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn2, 'second element should be fn2'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn3

  it 'should remove fn3 from array by itself (multiple) with reason', ->
    reason = 'the reason'
    chain.add fn2, fn3
    result = chain.remove fn3, reason
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.equal result.reason, reason
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn2, 'second element should be fn2'
    assert.strictEqual result.removed.length, 1, 'should remove one function'
    assert.strictEqual result.removed?[0], fn3


  it 'should remove via control', ->
    remover = (control) -> control.remove()
    chain.add remover, fn2
    assert.equal chain.array.length, 3, 'array should have 3'
    result = chain.run()
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn2, 'second element should be fn2'
    assert.strictEqual result.removed?[0], remover

  it 'should remove via control with reason', ->
    reason = 'the reason'
    remover = (control) -> control.remove reason
    chain.add remover, fn2
    assert.equal chain.array.length, 3, 'array should have 3'
    result = chain.run()
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn2, 'second element should be fn2'
    assert.strictEqual result.removed?[0], remover



  it 'should remove zero functions with falsey selector', ->
    chain.array = [ fn1, fn2, fn3 ]
    assert.equal chain.array.length, 3, 'array should start with 3'
    result = chain.select(-> false).remove()
    assert.equal chain.array.length, 3, 'array should be unchanged'
    assert.strictEqual result.removed, undefined, 'shouldnt be any removed'

  it 'should remove all functions with truthy selector', ->
    chain.array = [ fn1, fn2, fn3 ]
    result = chain.select(-> true).remove()
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.equal result.results.length, 3, 'there should be three internal action results'
    assert.strictEqual result.results[0].removed?[0], fn1
    assert.strictEqual result.results[1].removed?[0], fn2
    assert.strictEqual result.results[2].removed?[0], fn3

  it 'should remove one function with specific selector', ->
    chain.array = [ fn1, fn2, fn3 ]
    selector = (fn, index) -> (fn is fn2)
    result = chain.select(selector).remove()
    assert.equal chain.array.length, 2, 'array should be one less'
    assert.equal result.results.length, 1, 'there should be one internal action result'
    assert.strictEqual result.results[0].removed?[0], fn2

  it 'should remove two function with specific selector', ->
    chain.array = [ fn1, fn2, (->), fn3, (->) ]
    selector = (fn, index) -> (fn is fn2 or fn is fn3)
    result = chain.select(selector).remove()
    assert.equal chain.array.length, 3, 'array should be two less'
    assert.equal result.results.length, 2, 'there should be two internal action results'
    assert.strictEqual result.results[0].removed?[0], fn2


  it 'should remove zero functions with falsey selector', ->
    reason = 'the reason'
    chain.array = [ fn1, fn2, fn3 ]
    assert.equal chain.array.length, 3, 'array should start with 3'
    result = chain.select(-> false).remove reason
    assert.equal chain.array.length, 3, 'array should be unchanged'
    assert.strictEqual result.removed, undefined, 'shouldnt be any removed'

  it 'should remove all functions with truthy selector', ->
    reason = 'the reason'
    chain.array = [ fn1, fn2, fn3 ]
    result = chain.select(-> true).remove reason
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.equal result.results.length, 3, 'there should be three internal action results'
    assert.strictEqual result.results[0].removed?[0], fn1
    assert.strictEqual result.results[1].removed?[0], fn2
    assert.strictEqual result.results[2].removed?[0], fn3
    assert.equal result.results[0].reason, reason

  it 'should remove one function with specific selector', ->
    reason = 'the reason'
    chain.array = [ fn1, fn2, fn3 ]
    selector = (fn, index) -> (fn is fn2)
    result = chain.select(selector).remove reason
    assert.equal chain.array.length, 2, 'array should be one less'
    assert.equal result.results.length, 1, 'there should be one internal action result'
    assert.strictEqual result.results[0].removed?[0], fn2
    assert.equal result.results[0].reason, reason

  it 'should remove two function with specific selector', ->
    reason = 'the reason'
    chain.array = [ fn1, fn2, (->), fn3, (->) ]
    selector = (fn, index) -> (fn is fn2 or fn is fn3)
    result = chain.select(selector).remove reason
    assert.equal chain.array.length, 3, 'array should be two less'
    assert.equal result.results.length, 2, 'there should be two internal action results'
    assert.strictEqual result.results[0].removed?[0], fn2
    assert.equal result.results[0].reason, reason

  it 'should remove many functions with options selector', ->
    reason = 'the reason'
    f1 = ->
    f2 = ->
    f3 = ->
    f4 = ->
    f5 = ->
    f6 = ->
    f7 = ->
    options = select:true
    f2.options = f4.options = f6.options = options

    chain.array = [ f1, f2, f3, f4, f5, f6, f7 ]
    selector = (fn) -> (fn?.options?.select is true)
    result = chain.select(selector).remove reason
    assert.equal chain.array.length, 4, 'array should be three less'
    assert.equal result.results.length, 3, 'there should be three internal action results'
    assert.strictEqual result.results[0].removed?[0], f2
    assert.strictEqual result.results[1].removed?[0], f4
    assert.strictEqual result.results[2].removed?[0], f6
    assert.equal result.results[0].reason, reason


# 4. chain.clear()
describe 'test chain.clear()', ->
  fn1 = ->
  fn1.options = id:'fn1'
  fn2 = ->
  fn2.options = id:'fn2'
  fn3 = ->
  fn3.options = id:'fn3'
  chain = null
  beforeEach ->
    chain = buildChain()
    #; chain.add fn1, fn2, fn3

  it 'should remove nothing from empty chain', ->
    assert.equal chain.array.length, 0, 'array should be empty before clear()'
    result = chain.clear()
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.equal result.result, true
    assert.equal result.reason, 'chain empty'
    assert.strictEqual result.removed, undefined, 'result shouldnt have any removed'

  it 'should remove function from chain', ->
    chain.array = [ fn1 ]
    result = chain.clear()
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.strictEqual result.removed.length, 1, 'should remove three functions'
    assert.strictEqual result.removed?[0], fn1

  it 'should remove all functions from chain', ->
    chain.array = [ fn1, fn2, fn3 ]
    result = chain.clear()
    assert.equal chain.array.length, 0, 'array should be empty'
    assert.strictEqual result.removed.length, 3, 'should remove three functions'
    assert.strictEqual result.removed?[0], fn1
    assert.strictEqual result.removed?[1], fn2
    assert.strictEqual result.removed?[2], fn3



# 5. chain.run()
describe 'test running chain', ->
  ran  = (control, context) -> context.ran = true
  stop = ((control, context) -> context.stop = true ; control.stop 'testing')
  fail = ((control, context) -> context.fail = true ; control.fail 'testing')
  pause = (control, context) ->
    context.pause = true
    context.paused = true
    resume = control.pause 'testing'
    process.nextTick resume

  chain = null
  beforeEach ->
    chain = buildChain()

  it 'should catch thrown errors', ->
    theError = null
    theFn = ->
      theError = new Error 'my bad'
      throw theError

    chain.add theFn

    results = chain.run()

    assert results, 'should return results'
    assert.equal results.result, false, 'results should contain the result'
    assert.strictEqual results.failed?.error, theError, 'result should contain the `error`'
    assert.equal results.failed.error?.message, 'my bad'
    assert.equal results.failed?.reason, 'caught error'
    assert.equal results.failed?.index, 0, 'function should be first in the array'
    assert.strictEqual results.failed?.fn, theFn

  describe 'synch\'ly', ->

    it 'without specifying a context should use default context and return it', ->
      chain.add ran
      result = chain.run()
      assert result, 'should return a result object'
      assert.equal result?.context?.ran, true, 'should have a default context with `ran` = true'

    it 'with a specified context should use it and return it', ->
      context = {}
      chain.add ran
      result = chain.run context:context
      assert result, 'should return a result object'
      assert.strictEqual result.context, context, 'should be the same context object'
      assert.equal result?.context?.ran, true, 'should have the context with `ran` = true'

    it 'with an impermanent context override', ->
      contexts =
        original: context:true
        override: override:true
      override = (control, ctx) -> ctx.inOverride = true ; control.context contexts.override
      checkOverride = (control, ctx) -> contexts.overridden = ctx ; ctx.inCheck = true
      checkImpermanent = (control, ctx) -> contexts.impermanent = ctx ; ctx.inImpermanent = true
      chain.add ran, override, checkOverride, checkImpermanent
      result = chain.run context:contexts.original
      assert result, 'should return a result object'
      assert.equal result.context, contexts.original, 'should be the same context object'
      assert.deepEqual contexts.original,
        ran:true, context:true, inOverride:true, inImpermanent:true
      assert.deepEqual contexts.override, override:true, inCheck:true
      assert.equal contexts.overridden, contexts.override, 'context in check fn should be the override'
      assert.equal contexts.impermanent, contexts.original, 'context should revert to original context'

    it 'with a permanent context override', ->
      contexts =
        original: context:true
        override: override:true
      override = (control, ctx) -> ctx.inOverride = true ; control.context contexts.override, true
      checkOverride = (control, ctx) -> contexts.overridden = ctx ; ctx.inCheck = true
      checkPermanent = (control, ctx) -> contexts.permanent = ctx ; ctx.inPermanent = true
      chain.add ran, override, checkOverride, checkPermanent
      result = chain.run context:contexts.original
      assert result, 'should return a result object'
      assert.equal result.context, contexts.override, 'should be the permanently overridden context object'
      assert.deepEqual contexts.original,
        ran:true, context:true, inOverride:true
      assert.deepEqual contexts.override,
        override:true, inCheck:true, inPermanent:true
      assert.equal contexts.overridden, contexts.override, 'context in check fn should be the override'
      assert.equal contexts.permanent, contexts.override, 'context should NOT revert to original context'

    it 'with custom this', ->
      context = context:true
      customThis = custom:true
      receivedContext = null
      receivedThis = null
      fn1 = (control, ctx) ->
        receivedContext = ctx
        receivedThis = this
        this.isThis = true
      fn1.options = this:customThis
      chain.add fn1
      result = chain.run context:context
      assert result, 'should return a result object'
      assert.strictEqual receivedContext, context, 'should be the same context'
      assert.strictEqual receivedThis, customThis, 'should be the custom this'
      assert.equal customThis.isThis, true, 'should have isThis in customThis'

    it 'with a stop call', ->
      context = context:true
      fn1 = (control, ctx) -> ctx.fn1 = true
      fn2 = (control, ctx) -> ctx.fn2 = true ; control.stop 'testing'
      fn3 = (control, ctx) -> ctx.fn3 = true
      chain.add fn1, fn2, fn3
      result = chain.run context:context
      assert result, 'should return a result object'
      assert.equal context.fn1, true, 'should call fn1'
      assert.equal context.fn2, true, 'should call fn2'
      assert.strictEqual context.fn3, undefined, 'should *not* call fn3'
      assert result.stopped, 'should have `stopped` info'
      assert.equal result.stopped.reason, 'testing'
      assert.strictEqual result.stopped.fn, fn2, 'should have fn2 as the stopping `fn`'

    it 'with a fail call', ->
      context = context:true
      fn1 = (control, ctx) -> ctx.fn1 = true
      fn2 = (control, ctx) -> ctx.fn2 = true ; control.fail 'testing'
      fn3 = (control, ctx) -> ctx.fn3 = true
      chain.add fn1, fn2, fn3
      result = chain.run context:context
      assert result, 'should return a result object'
      assert.equal context.fn1, true, 'should call fn1'
      assert.equal context.fn2, true, 'should call fn2'
      assert.strictEqual context.fn3, undefined, 'should *not* call fn3'
      assert result.failed, 'should have `failed` info'
      assert.equal result.failed.reason, 'testing'
      assert.strictEqual result.failed.fn, fn2, 'should have fn2 as the stopping `fn`'

    it 'should allow next() to do work afterwards', ->
      calls = []
      first = -> calls.push 'first'
      nexter = (control) ->
        calls.push 'nexter: pre-next()'
        result = control.next()
        calls.push 'nexter: post-next()'
        return result
      last = -> calls.push 'last'

      chain.add first, nexter, last
      results = chain.run()

      assert results.result, 'should have successful result'
      assert.equal calls.length, 4, 'should call each function, and nexter twice'
      assert.deepEqual calls, [ 'first', 'nexter: pre-next()', 'last', 'nexter: post-next()' ]

    it 'should allow next() to do work afterwards, and temporarily override context', ->
      mainContext = temp:false
      tempContext = temp:true
      calls = []
      first = ->
        @first = true # goes into the main context
        calls.push 'first'

      third = ->
        @third = true # goes into the tempContext
        calls.push 'third'

      last = ->
        @last = true # goes into the mainContext
        calls.push 'last'

      nexter = (control) ->
        @nexter = true
        calls.push 'nexter: pre-next()'

        result = control.next tempContext

        calls.push 'nexter: post-next()'

        return result

      chain.add first, nexter, third, last
      results = chain.run context:mainContext

      assert results.result, 'should have successful result'
      assert.equal calls.length, 5, 'should call each function, and nexter twice'
      assert.deepEqual calls, [
        'first', 'nexter: pre-next()', 'third', 'last', 'nexter: post-next()'
      ]
      assert.strictEqual results.context, mainContext
      assert mainContext.first, 'first function should get mainContext'
      assert mainContext.nexter, 'nexter function should get mainContext'
      assert tempContext.third, 'third function should get tempContext'
      assert mainContext.last, 'last function should get mainContext'

    it 'should allow next() to do work afterwards, and permanently override context', ->
      mainContext = override:false
      newContext = override:true
      calls = []
      first = ->
        @first = true # goes into the main context
        calls.push 'first'

      third = ->
        @third = true # goes into the newContext
        calls.push 'third'

      last = ->
        @last = true # goes into the newContext
        calls.push 'last'

      nexter = (control) ->
        @nexter = true
        calls.push 'nexter: pre-next()'

        result = control.next newContext, true

        calls.push 'nexter: post-next()'

        return result

      chain.add first, nexter, third, last
      results = chain.run context:mainContext

      assert results.result, 'should have successful result'
      assert.equal calls.length, 5, 'should call each function, and nexter twice'
      assert.deepEqual calls, [
        'first', 'nexter: pre-next()', 'third', 'last', 'nexter: post-next()'
      ]
      assert.strictEqual results.context, newContext, 'the original context is replaced permanently'
      assert results.context.override, 'should be the override one'
      assert mainContext.first, 'first function should get original context'
      assert mainContext.nexter, 'nexter function should get original context'
      assert newContext.third, 'third function should get override context'
      assert newContext.last, 'last function should get override context'


    it 'should allow next() to do work afterwards, twice', ->
      calls = []
      first = -> calls.push 'first'
      nexter = (control) ->
        calls.push 'nexter: pre-next()'
        result = control.next()
        calls.push 'nexter: post/pre-next()'
        result = control.next()
        calls.push 'nexter: post-next()'
        return result
      last = -> calls.push 'last'

      chain.add first, nexter, last
      results = chain.run()

      assert results.result, 'should have successful result'
      assert.equal calls.length, 6, 'should call first once, nexter 3 times, and last twice'
      assert.deepEqual calls, [
        'first', 'nexter: pre-next()', 'last',
        'nexter: post/pre-next()', 'last',
        'nexter: post-next()'
      ]

    it 'should allow next() to do work afterwards, twice', ->
      calls = []
      first = -> calls.push 'first'
      nexter = (control) ->

        calls.push 'nexter: pre-next()'
        result = control.next()

        calls.push 'nexter: post/pre-next()'
        result = control.next()

        calls.push 'nexter: post/pre-next()'
        result = control.next()

        calls.push 'nexter: post-next()'

        return result

      last = -> calls.push 'last'

      chain.add first, nexter, last
      results = chain.run()

      assert results.result, 'should have successful result'
      assert.equal calls.length, 8, 'should call first once, nexter 4 times, and last 3 times'
      assert.deepEqual calls, [
        'first', 'nexter: pre-next()', 'last',
        'nexter: post/pre-next()', 'last',
        'nexter: post/pre-next()', 'last',
        'nexter: post-next()'
      ]

  # b. async
  # TODO: really, the above tests using control.next() are async-ish...
  # TODO: change synch stuff above to *not* call next, move those down here.
  describe 'asynch\'ly', ->
    unpaused = -> this.paused = false
    beforeEach ->
      chain.add pause, unpaused, ran

    it 'without specifying a context should use default context and return it', (done) ->
      syncResult = chain.run done: (error, results) ->
        if error? then return done error
        assert results, 'should receive a results object'
        assert.equal results?.context?.pause, true, 'should have called pause() and set pause=true'
        assert.equal results?.context?.ran, true, 'should have called ran and set ran=true'
        assert.equal results?.context?.paused, false, 'should have called last fn and set paused=false'
        assert.deepEqual syncResult?.paused, reason:'testing', index:0, fn:pause
        done()

    it 'with a specified context should use it and return it', (done) ->
      context = {}
      syncResult = chain.run context:context, done: (error, result) ->
        if error? then return done error
        assert result, 'should return a result object'
        assert.equal result?.context?.pause, true, 'should have called pause() and set pause=true'
        assert.equal result?.context?.ran, true, 'should have called ran and set ran=true'
        assert.equal result?.context?.paused, false, 'should have called last fn and set paused=false'
        assert.deepEqual syncResult?.paused, reason:'testing', index:0, fn:pause
        done()

    it 'with an impermanent context override', (done) ->
      contexts =
        original: context:true
        override: override:true
      override = (control, ctx) -> ctx.inOverride = true ; control.context contexts.override
      checkOverride = (control, ctx) -> contexts.overridden = ctx ; ctx.inCheck = true
      checkImpermanent = (control, ctx) -> contexts.impermanent = ctx ; ctx.inImpermanent = true
      chain.array.splice 0, 0, override, checkOverride
      chain.add checkImpermanent
      syncResult = chain.run context:contexts.original, done: (error, result) ->
        assert result, 'should return a result object'
        assert.equal result.context, contexts.original, 'should be the same context object'
        assert.deepEqual contexts.original,
          ran:true, context:true, inOverride:true, inImpermanent:true, pause:true, paused:false
        assert.deepEqual contexts.override, override:true, inCheck:true
        assert.equal contexts.overridden, contexts.override, 'context in check fn should be the override'
        assert.equal contexts.impermanent, contexts.original, 'context should revert to original context'

        assert.equal result?.context?.pause, true, 'should have called pause() and set pause=true'
        assert.equal result?.context?.ran, true, 'should have called ran and set ran=true'
        assert.equal result?.context?.paused, false, 'should have called last fn and set paused=false'
        assert.deepEqual syncResult?.paused, reason:'testing', index:2, fn:pause
        done()

    it 'with a permanent context override', (done) ->
      contexts =
        original: context:true
        override: override:true
      override = (control, ctx) -> ctx.inOverride = true ; control.context contexts.override, true
      checkOverride = (control, ctx) -> contexts.overridden = ctx ; ctx.inCheck = true
      checkPermanent = (control, ctx) -> contexts.permanent = ctx ; ctx.inPermanent = true
      chain.array.unshift override
      chain.add checkOverride, checkPermanent
      syncResult = chain.run context:contexts.original, done:(error, result) ->
        assert result, 'should return a result object'
        assert.equal result.context, contexts.override, 'should be the permanently overridden context object'
        assert.deepEqual contexts.original,
          context:true, inOverride:true
        assert.deepEqual contexts.override,
          override:true, inCheck:true, inPermanent:true, ran:true, pause:true, paused:false
        assert.equal contexts.overridden, contexts.override, 'context in check fn should be the override'
        assert.equal contexts.permanent, contexts.override, 'context should NOT revert to original context'

        assert.equal result?.context?.pause, true, 'should have called pause() and set pause=true'
        assert.equal result?.context?.ran, true, 'should have called ran and set ran=true'
        assert.equal result?.context?.paused, false, 'should have called last fn and set paused=false'
        assert.deepEqual syncResult?.paused, reason:'testing', index:1, fn:pause
        done()

    it 'with custom this', (done) ->
      context = context:true
      customThis = custom:true
      receivedContext = null
      receivedThis = null
      fn1 = (control, ctx) ->
        receivedContext = ctx
        receivedThis = this
        this.isThis = true
      fn1.options = this:customThis
      chain.add fn1
      syncResult = chain.run context:context, done: (error, result) ->
        assert result, 'should return a result object'
        assert.strictEqual receivedContext, context, 'should be the same context'
        assert.strictEqual receivedThis, customThis, 'should be the custom this'
        assert.equal customThis.isThis, true, 'should have isThis in customThis'

        assert.equal result?.context?.pause, true, 'should have called pause() and set pause=true'
        assert.equal result?.context?.ran, true, 'should have called ran and set ran=true'
        assert.equal result?.context?.paused, false, 'should have called last fn and set paused=false'
        assert.deepEqual syncResult?.paused, reason:'testing', index:0, fn:pause
        done()

    it 'with a stop call', (done) ->
      context = context:true
      fn1 = (control, ctx) -> ctx.fn1 = true
      fn2 = (control, ctx) -> ctx.fn2 = true ; control.stop 'testing'
      fn3 = (control, ctx) -> ctx.fn3 = true
      chain.add fn1, fn2, fn3
      syncResult = chain.run context:context, done: (error, result) ->
        assert result, 'should return a result object'
        assert.equal context.fn1, true, 'should call fn1'
        assert.equal context.fn2, true, 'should call fn2'
        assert.strictEqual context.fn3, undefined, 'should *not* call fn3'
        assert result.stopped, 'should have `stopped` info'
        assert.equal result.stopped.reason, 'testing'
        assert.strictEqual result.stopped.fn, fn2, 'should have fn2 as the stopping `fn`'

        assert.equal result?.context?.pause, true, 'should have called pause() and set pause=true'
        assert.equal result?.context?.ran, true, 'should have called ran and set ran=true'
        assert.equal result?.context?.paused, false, 'should have called last fn and set paused=false'
        assert.deepEqual syncResult?.paused, reason:'testing', index:0, fn:pause
        done()

    it 'with a fail call', (done) ->
      context = context:true
      fn1 = (control, ctx) -> ctx.fn1 = true
      fn2 = (control, ctx) -> ctx.fn2 = true ; control.fail 'testing'
      fn3 = (control, ctx) -> ctx.fn3 = true
      chain.add fn1, fn2, fn3
      syncResult = chain.run context:context, done: (error, result) ->
        assert result, 'should return a result object'
        assert.equal context.fn1, true, 'should call fn1'
        assert.equal context.fn2, true, 'should call fn2'
        assert.strictEqual context.fn3, undefined, 'should *not* call fn3'
        assert result.failed, 'should have `failed` info'
        assert.equal result.failed.reason, 'testing'
        assert.strictEqual result.failed.fn, fn2, 'should have fn2 as the stopping `fn`'

        assert.equal result?.context?.pause, true, 'should have called pause() and set pause=true'
        assert.equal result?.context?.ran, true, 'should have called ran and set ran=true'
        assert.equal result?.context?.paused, false, 'should have called last fn and set paused=false'
        assert.deepEqual syncResult?.paused, reason:'testing', index:0, fn:pause
        done()


    it 'with resume callback defaults and success', (done) ->

      # empty the array for this test
      chain.array = []

      # add in our resumer function
      chain.add (control, context) ->
        resume = control.pause 'testing resume.callback'
        callback = resume.callback()
        # call it later...
        process.nextTick -> callback null, 'result'

      # run with default context, we can check it from result
      result = chain.run done:(err, res) ->
        assert.equal err, undefined, 'shouldnt be an error'
        assert.equal res?.context?.result, 'result'

        done()

    it 'with resume callback key name and success', (done) ->

      # empty the array for this test
      chain.array = []

      # add in our resumer function
      chain.add (control, context) ->
        resume = control.pause 'testing resume.callback'
        callback = resume.callback null, 'mykey'
        # call it later...
        process.nextTick -> callback null, 'value'

      # run with default context, we can check it from result
      result = chain.run done:(err, res) ->
        assert.equal err, undefined, 'shouldnt be an error'
        assert.equal res?.context?.mykey, 'value'

        done()

    it 'with resume callback error message and failure', (done) ->

      # empty the array for this test
      chain.array = []

      failer = (control, context) ->
        resume = control.pause 'testing resume.callback'
        callback = resume.callback 'error!', 'mykey'
        # call it later...
        process.nextTick -> callback new Error 'some Error'

      # add in our resumer function
      chain.add failer

      # run with default context, we can check it from result
      result = chain.run done:(err, res) ->
        assert.equal err.reason, 'error!'
        assert.equal err.index, 0, 'should have failing function at 0'
        assert.strictEqual err.fn, failer
        assert.equal err.error.message, 'some Error', 'should have message from Error instance'
        assert.strictEqual res?.context?.mykey, undefined

        done()





# 6. disable
# - chain.disable()
# - chain.disable('reason')
#
# - chain.disable(index)
# - chain.disable(index, 'reason')
#
# - chain.disable('someid')
# - chain.disable('someid', 'reason')
#
# - chain.disable(someFn)
# - chain.disable(someFn, 'reason')
#
# - control.disable()
# - control.disable('reason')
#
# - select(fn).disable()        - single
# - select(fn).disable(reason)  - single
#
# - select(fn).disable()        - duo
# - select(fn).disable(reason)  - duo


describe 'test disable', ->

  fn1 = ->
  fn1.options = id:'fn1'
  fn2 = ->
  fn2.options = id:'fn2'
  fn3 = ->
  fn3.options = id:'fn3'

  chain = null

  beforeEach ->
    chain = buildChain()

  it 'should disable the chain with a default reason', ->

    called = []
    caller1 = -> called.push 1
    caller1.options = id:'caller1'
    caller2 = -> called.push 2
    caller2.options = id:'caller2'
    caller3 = -> called.push 3
    caller3.options = id:'caller3'
    chain.add caller1, caller2, caller3

    results1 = chain.run()
    results2 = chain.disable()
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'disable should succeed'
    assert results2.reason, 'disable reason should default to true'
    assert.equal results3.result, false, 'second run should fail due to being disabled'
    assert.equal results3.reason, 'chain disabled'
    assert.equal results3.disabled, true
    assert.equal called.length, 3, 'chain should be called only once (for 3 functions)'
    assert.deepEqual called, [ 1, 2, 3]

  it 'should disable the chain with a specified reason', ->

    reason = 'the reason'
    called = []
    caller1 = -> called.push 1
    caller1.options = id:'caller1'
    caller2 = -> called.push 2
    caller2.options = id:'caller2'
    caller3 = -> called.push 3
    caller3.options = id:'caller3'
    chain.add caller1, caller2, caller3

    results1 = chain.run()
    results2 = chain.disable reason
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'disable should succeed'
    assert results2.reason, 'disable reason should default to true'
    assert.equal results3.result, false, 'second run should fail due to being disabled'
    assert.equal results3.reason, 'chain disabled'
    assert.equal results3.disabled, reason
    assert.equal called.length, 3, 'chain should be called only once (for 3 functions)'
    assert.deepEqual called, [ 1, 2, 3]


  it 'should disable the function by index with default reason', ->

    called = []
    caller = -> called.push true
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.disable 1
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'disable should succeed'
    assert results2.reason, 'disable reason should default to true'
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'

  it 'should disable the function by index with specific reason', ->
    reason = 'the reason'
    called = []
    caller = -> called.push true
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.disable 1, reason
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'disable should succeed'
    assert.equal results2.reason, reason
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'


  # NOTE: you can't use default reason with an id.

  it 'should disable the function by id with specific reason', ->
    reason = 'the reason'
    called = []
    caller = -> called.push true
    caller.options = id:'caller'
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.disable 'caller', reason
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'disable should succeed'
    assert.equal results2.reason, reason
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'


  it 'should disable the function by function with default reason', ->

    called = []
    caller = -> called.push true
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.disable caller
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'disable should succeed'
    assert results2.reason, 'disable reason should default to true'
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'

  it 'should disable the function by function with specific reason', ->
    reason = 'the reason'
    called = []
    caller = -> called.push true
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.disable caller, reason
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'disable should succeed'
    assert.equal results2.reason, reason
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'


  it 'should disable via control with default reason', ->
    disabler = (control) -> control.disable()
    chain.add fn1, disabler, fn3
    assert.equal chain.array.length, 3, 'should start with 3 functions'
    chain.run()
    assert.equal chain.array.length, 3, 'should still have 3 functions'
    assert.equal chain.array[1].options.disabled, true

  it 'should disable via control with specific reason', ->
    reason = 'the reason'
    disabler = (control) -> control.disable reason
    chain.add fn1, disabler, fn3
    assert.equal chain.array.length, 3, 'should start with 3 functions'
    chain.run()
    assert.equal chain.array.length, 3, 'should still have 3 functions'
    assert.equal chain.array[1].options.disabled, reason


  it 'should select() a function and disable with default reason', ->
    target = ->
    selector = (fn, index) -> (fn is target and index is 1)
    chain.add fn1, target, fn3
    assert.equal chain.array.length, 3, 'should start with 3 functions'
    result = chain.select(selector).disable()
    assert.equal chain.array.length, 3, 'should still have 3 functions'
    assert.equal target.options.disabled, true
    assert.equal chain.array[1].options.disabled, true

  it 'should select() a function and disable with specific reason', ->
    reason = 'the reason'
    target = ->
    selector = (fn, index) -> (fn is target and index is 1)
    chain.add fn1, target, fn3
    assert.equal chain.array.length, 3, 'should start with 3 functions'
    chain.select(selector).disable reason
    assert.equal chain.array.length, 3, 'should still have 3 functions'
    assert.equal target.options.disabled, reason
    assert.equal chain.array[1].options.disabled, reason


  it 'should select() two functions and disable with default reason', ->
    reason = true
    target1 = ->
    target2 = ->
    selector = (fn, index) ->
      (fn is target1 and index is 1) or (fn is target2 and index is 2)
    chain.add fn1, target1, target2, fn3
    assert.equal chain.array.length, 4, 'should start with 3 functions'
    chain.select(selector).disable()
    assert.equal chain.array.length, 4, 'should still have 3 functions'
    assert.equal target1.options.disabled, reason
    assert.equal target2.options.disabled, reason
    assert.equal chain.array[1].options.disabled, reason
    assert.equal chain.array[2].options.disabled, reason

  it 'should select() two functions and disable with specific reason', ->
    reason = 'the reason'
    target1 = ->
    target2 = ->
    selector = (fn, index) ->
      (fn is target1 and index is 1) or (fn is target2 and index is 2)
    chain.add fn1, target1, target2, fn3
    assert.equal chain.array.length, 4, 'should start with 3 functions'
    chain.select(selector).disable reason
    assert.equal chain.array.length, 4, 'should still have 3 functions'
    assert.equal target1.options.disabled, reason
    assert.equal target2.options.disabled, reason
    assert.equal chain.array[1].options.disabled, reason
    assert.equal chain.array[2].options.disabled, reason




# 7. enable
# - chain.enable()
# - chain.enable(index)
# - chain.enable('someid')
# - chain.enable(someFn)
# - select(fn).enable()        - single
# - select(fn).enable()        - duo

describe 'test enable', ->

  fn1 = ->
  fn1.options = id:'fn1'
  fn2 = ->
  fn2.options = id:'fn2'
  fn3 = ->
  fn3.options = id:'fn3'

  chain = null

  beforeEach ->
    chain = buildChain()

  it 'should have false result if chain is already enabled', ->

    results = chain.enable()

    assert.equal results.result, false, 'should fail because it\'s already enabled'
    assert.equal results.reason, 'chain not disabled'

  it 'should enable the chain', ->

    called = []
    caller1 = -> called.push 1
    caller1.options = id:'caller1'
    caller2 = -> called.push 2
    caller2.options = id:'caller2'
    caller3 = -> called.push 3
    caller3.options = id:'caller3'
    chain.add caller1, caller2, caller3

    chain._disabled = true
    results1 = chain.run()
    results2 = chain.enable()
    results3 = chain.run()

    assert.equal results1.result, false, 'first run should fail because it\'s disabled'
    assert results2.result, 'enable should succeed'
    assert results3.result, 'second run should succeed due to being enabled'
    assert.equal results3.disabled, undefined
    assert.equal called.length, 3, 'chain should be called only once (for 3 functions)'
    assert.deepEqual called, [ 1, 2, 3]


  it 'should have false result if function is already enabled', ->

    chain.add fn1
    results = chain.enable 0

    assert.equal results.result, false, 'should fail because it\'s already enabled'
    assert.equal results.reason, 'function not disabled'

  it 'should enable the function by index', ->

    called = []
    caller = -> called.push true
    caller.options = disabled:true
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.enable 1
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'enable should succeed'
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'
    assert.equal caller.options.disabled, undefined, 'should delete the `disabled` marker'


  it 'should enable the function by id', ->
    called = []
    caller = -> called.push true
    caller.options = disabled:true, id:'caller'
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.enable 'caller'
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'enable should succeed'
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'
    assert.equal caller.options.disabled, undefined, 'should delete the `disabled` marker'
    assert.equal caller.options.id, 'caller', 'should still have the id in options'


  it 'should enable the function by function', ->

    called = []
    caller = -> called.push true
    caller.options = disabled:true
    chain.add fn1, caller, fn3

    results1 = chain.run()
    results2 = chain.enable caller
    results3 = chain.run()

    assert results1.result, 'first run should succeed'
    assert results2.result, 'enable should succeed'
    assert results3.result, 'second run should succeed'
    assert.equal called.length, 1, 'should be called only once'
    assert.equal caller.options.disabled, undefined, 'should delete the `disabled` marker'



  it 'should select() a function and enable', ->

    target = ->
    target.options = disabled:true
    selector = (fn, index) -> (fn is target and index is 1)
    chain.add fn1, target, fn3
    assert.equal chain.array.length, 3, 'should start with 3 functions'
    chain.select(selector).enable()
    assert.equal chain.array.length, 3, 'should still have 3 functions'
    assert.equal target.options.disabled, undefined
    assert.equal chain.array[1].options.disabled, undefined


  it 'should select() two functions and enable', ->

    target1 = ->
    target1.options = disabled:true
    target2 = ->
    target2.options = disabled:true
    selector = (fn, index) ->
      (fn is target1 and index is 1) or (fn is target2 and index is 2)
    chain.add fn1, target1, target2, fn3
    assert.equal chain.array.length, 4, 'should start with 3 functions'
    chain.select(selector).enable()
    assert.equal chain.array.length, 4, 'should still have 3 functions'
    assert.equal target1.options.disabled, undefined
    assert.equal target2.options.disabled, undefined
    assert.equal chain.array[1].options.disabled, undefined
    assert.equal chain.array[2].options.disabled, undefined

# 8. select()

describe 'test select', ->

  chain = null

  beforeEach 'create a chain', ->
    chain = buildChain()

  it 'should error if `selector` isnt a function', ->

    result = chain.select null

    assert result.error, 'result should contain an error'
    assert result.disable, 'result should contain disable'
    assert result.enable, 'result should contain enable'
    assert result.remove, 'result should contain remove'
    assert result.affect, 'result should contain affect'
    assert.equal result.error, 'Selector must be an index, id, or filter function'
    error = result.error

    assert.strictEqual result.disable().error, error
    assert.strictEqual result.enable().error, error
    assert.strictEqual result.remove().error, error
    assert.strictEqual result.affect().error, error

  it 'should error if `selector` isnt a function', ->

    result = chain.select false

    assert result.error, 'result should contain an error'
    assert result.disable, 'result should contain disable'
    assert result.enable, 'result should contain enable'
    assert result.remove, 'result should contain remove'
    assert result.affect, 'result should contain affect'
    assert.equal result.error, 'Selector must be an index, id, or filter function'
    error = result.error

    assert.strictEqual result.disable().error, error
    assert.strictEqual result.enable().error, error
    assert.strictEqual result.remove().error, error
    assert.strictEqual result.affect().error, error

  it 'should error if `selector` isnt a function', ->

    result = chain.select 'string'

    assert result.error, 'result should contain an error'
    assert result.disable, 'result should contain disable'
    assert result.enable, 'result should contain enable'
    assert result.remove, 'result should contain remove'
    assert result.affect, 'result should contain affect'
    assert.equal result.error, 'Selector must be an index, id, or filter function'
    error = result.error

    assert.strictEqual result.disable().error, error
    assert.strictEqual result.enable().error, error
    assert.strictEqual result.remove().error, error
    assert.strictEqual result.affect().error, error

  it 'should error if `selector` isnt a function', ->

    result = chain.select 123

    assert result.error, 'result should contain an error'
    assert result.disable, 'result should contain disable'
    assert result.enable, 'result should contain enable'
    assert result.remove, 'result should contain remove'
    assert result.affect, 'result should contain affect'
    assert.equal result.error, 'Selector must be an index, id, or filter function'
    error = result.error

    assert.strictEqual result.disable().error, error
    assert.strictEqual result.enable().error, error
    assert.strictEqual result.remove().error, error
    assert.strictEqual result.affect().error, error

  it 'should error if `selector` isnt a function', ->

    result = chain.select {}

    assert result.error, 'result should contain an error'
    assert result.disable, 'result should contain disable'
    assert result.enable, 'result should contain enable'
    assert result.remove, 'result should contain remove'
    assert result.affect, 'result should contain affect'
    assert.equal result.error, 'Selector must be an index, id, or filter function'
    error = result.error

    assert.strictEqual result.disable().error, error
    assert.strictEqual result.enable().error, error
    assert.strictEqual result.remove().error, error
    assert.strictEqual result.affect().error, error

  it 'should error if `selector` isnt a function', ->

    result = chain.select []

    assert result.error, 'result should contain an error'
    assert result.disable, 'result should contain disable'
    assert result.enable, 'result should contain enable'
    assert result.remove, 'result should contain remove'
    assert result.affect, 'result should contain affect'
    assert.equal result.error, 'Selector must be an index, id, or filter function'
    error = result.error

    assert.strictEqual result.disable().error, error
    assert.strictEqual result.enable().error, error
    assert.strictEqual result.remove().error, error
    assert.strictEqual result.affect().error, error


# 9. select().affect()

describe 'test select', ->

  fn1 = ->
  fn1.options = id:'fn1'
  fn2 = ->
  fn2.options = id:'fn2'
  fn3 = ->
  fn3.options = id:'fn3'

  chain = null

  beforeEach ->
    chain = buildChain()

  it 'should call affector on selected function', ->
    target = ->
    target.options = id:'target'
    chain.add fn1, fn2, target, fn3

    selector = (fn) -> fn is target
    selected = chain.select selector

    returnValue = 'return value'
    affector = (fn) ->
      fn.options.labels ?= []
      fn.options.labels.push 'affected'
      return returnValue

    result = selected.affect affector

    assert target.options.labels, 'should have created a labels array'
    assert.equal target.options.labels?[0], 'affected'
    assert.equal result?.results?[0], returnValue
