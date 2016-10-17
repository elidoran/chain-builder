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
  beforeEach -> chain = buildChain()

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


# 3. chain.remove()
describe 'test chain.remove()', ->
  fn1 = ->
  fn2 = ->
  fn3 = ->
  chain = null
  beforeEach -> chain = buildChain() ; chain.add fn1

  it 'should remove fn1 from array', ->
    chain.remove fn1
    assert.equal chain.array.length, 0, 'array should be empty'

  it 'should remove fn1 from array', ->
    chain.add fn2, fn3
    chain.remove fn1
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn2, 'first element should be fn2'
    assert.strictEqual chain.array[1], fn3, 'first element should be fn3'

  it 'should remove fn2 from array', ->
    chain.add fn2, fn3
    chain.remove fn2
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn3, 'first element should be fn3'

  it 'should remove fn3 from array', ->
    chain.add fn2, fn3
    chain.remove fn3
    assert.equal chain.array.length, 2, 'array should be one less: 2'
    assert.strictEqual chain.array[0], fn1, 'first element should be fn1'
    assert.strictEqual chain.array[1], fn2, 'first element should be fn2'

# 4. chain.run()
describe 'test running chain', ->
  ran  = (control, context) -> context.ran = true
  stop = (control, context) -> context.stop = true ; control.stop 'testing'
  fail = (control, context) -> context.fail = true ; control.fail 'testing'
  pause = (control, context) ->
    context.pause = true
    context.paused = true
    resume = control.pause 'testing'
    process.nextTick resume

  chain = null
  beforeEach -> chain = buildChain()

  it 'should catch thrown errors', ->
    chain.add -> throw new Error 'my bad'
    results = chain.run()
    assert results, 'should return results'
    assert results.result, 'results should contain the result'
    assert results.result.error, 'result should contain the `error`'
    assert.equal results.result.error.message, 'my bad'

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

  # b. async
  # TODO: really, the above tests using control.next() are async-ish...
  # TODO: change synch stuff above to *not* call next, move those down here.
  describe 'asynch\'ly', ->
    unpaused = -> this.paused = false
    beforeEach -> chain.add pause, unpaused, ran

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
