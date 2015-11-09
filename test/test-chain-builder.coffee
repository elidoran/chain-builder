assert = require 'assert'
buildChain = require '../index'

noop = /function\s?\(\)\s?{\n\s*return had\.success\(\);\n\s*}/

# TODO: these helpers should probably be provided by `had`
assertSuccess = (result, exists, equals) ->
  assert.equal result?.success?, true, 'result.success should exist'
  assert.equal result.success, true, 'result.success should equal true'
  assertValues result, exists, equals

assertValues = (result, exists, equals) ->
  if exists?
    for key in exists
      assert.equal result?[key]?, true, "#{key} should exist"

  if equals?
    for own key,value of equals
      assert.equal result?[key], value, "#{key} should equal #{value}"

assertError = (result, exists, equals) ->
  assert.equal result?.error?, true, 'result.error should exist'
  assert.equal result?.type?, true, 'result.type should exist'
  assertValues result, exists, equals

describe 'test building chains/pipelines', ->

  describe 'test passing bad values to chain/pipeline', ->

    describe 'test null to chain', ->

      it 'should return error', ->
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: null
          in: [null]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain null
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test null to pipeline', ->

      it 'should return error', ->
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: null
          in: [null]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline null
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test undefined to chain', ->

      it 'should return error', ->
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: undefined
          in: [undefined]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain undefined
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test undefined to pipeline', ->

      it 'should return error', ->
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: undefined
          in: [undefined]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline undefined
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test undefined in array to chain', ->

      it 'should return error', ->
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: undefined
          in: [undefined]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain [undefined]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test undefined in array to pipeline', ->

      it 'should return error', ->
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: undefined
          in: [undefined]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline [undefined]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test null in array to chain', ->

      it 'should return error', ->
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: null
          in: [null]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain [null]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test null in array to pipeline', ->

      it 'should return error', ->
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: null
          in: [null]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline [null]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test Object in array to chain', ->

      it 'should return error', ->
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: {}
          in: [{}]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain [{}]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test Object in array to pipeline', ->

      it 'should return error', ->
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: {}
          in: [{}]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline [{}]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test string in array to chain', ->

      it 'should return error', ->
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: 'string'
          in: ['string']
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain ['string']
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test string in array to pipeline', ->

      it 'should return error', ->
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: 'string'
          in: ['string']
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline ['string']
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test number in array to chain', ->

      it 'should return error', -> # -1
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: -1
          in: [-1]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain [-1]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test number in array to pipeline', ->

      it 'should return error', ->
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: -1
          in: [-1]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline [-1]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test Date in array to chain', ->

      it 'should return error', -> # new Date
        date = new Date()
        expected =
          had: 'chain'
          error: 'not a function'
          type: 'typeof'
          on: date
          in: [date]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.chain [date]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

    describe 'test Date in array to pipeline', ->

      it 'should return error', ->
        date = new Date()
        expected =
          had: 'pipeline'
          error: 'not a function'
          type: 'typeof'
          on: date
          in: [date]
          name:'fn'
          index:0
          during: 'array content validation'
        result = builder.pipeline [date]
        assert.equal result?, true, 'result should exist'
        assert.deepEqual result, expected

  describe 'test successful runs', ->

    describe 'test empty chain', ->

      it 'should return a noop function', ->
        result = builder.chain []
        console.log 'RESULT CHAIN=',result.chain
        assertSuccess result, ['chain']
        assert.equal noop.test(''+result.chain), true

    describe 'test empty pipeline', ->

      it 'should return a noop function', ->
        result = builder.pipeline []
        assertSuccess result, ['pipeline']
        assert.equal noop.test(''+result.pipeline), true

    describe 'test single input to chain', ->

      it 'should give a chain for the single function', ->
        ctx =
          ran: false
        com = (context) -> ctx.ran = true
        result = builder.chain [com]
        assertSuccess result, ['chain']
        result = result.chain ctx
        assertSuccess result
        assert.equal ctx.ran, true

    describe 'test single input to pipeline', ->

      it 'should give a pipeline for the single function', ->
        ctx =
          ran: false
        com = (next, context) -> ctx.ran = true ; next context
        result = builder.pipeline [com]
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assertSuccess result
        assert.equal ctx.ran, true

  describe 'test providing functions instead of array', ->

    describe 'test one function to chain', ->

      it 'should give a chain for the one function', ->
        ctx = ran:false
        com = (context) -> context.ran = true
        result = builder.chain com
        assertSuccess result, ['chain']
        result = result.chain ctx
        assertSuccess result
        assert.equal ctx.ran, true

    describe 'test one function to pipeline', ->

      it 'should give a pipeline for the one function', ->
        ctx = ran:false
        com = (next, context) -> context.ran = true ; next context
        result = builder.pipeline com
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assertSuccess result
        assert.equal ctx.ran, true

    describe 'test two functions to chain', ->

      it 'should give a chain for the two functions', ->
        ctx = ran1: false, ran2: false
        com1 = (context) -> context.ran1 = true
        com2 = (context) -> context.ran2 = true
        result = builder.chain com1, com2
        assertSuccess result, ['chain']
        result = result.chain ctx
        assertSuccess result
        assert.equal ctx.ran1, true
        assert.equal ctx.ran2, true

    describe 'test two functions to pipeline', ->

      it 'should give a pipeline for the two functions', ->
        ctx = ran1: false, ran2: false
        com1 = (next, context) -> context.ran1 = true ; next context
        com2 = (next, context) -> context.ran2 = true ; next context
        result = builder.pipeline com1, com2
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assertSuccess result
        assert.equal ctx.ran1, true
        assert.equal ctx.ran2, true

    describe 'test three functions to chain', ->

      it 'should give a chain for the three functions', ->
        ctx = ran1: false, ran2: false, ran3: false
        com1 = (context) -> context.ran1 = true
        com2 = (context) -> context.ran2 = true
        com3 = (context) -> context.ran3 = true
        result = builder.chain com1, com2, com3
        assertSuccess result, ['chain']
        result = result.chain ctx
        assertSuccess result
        assert.equal ctx.ran1, true
        assert.equal ctx.ran2, true
        assert.equal ctx.ran3, true

    describe 'test three functions to pipeline', ->

      it 'should give a pipeline for the three functions', ->
        ctx = ran1: false, ran2: false, ran3: false
        com1 = (next, context) -> context.ran1 = true ; next context
        com2 = (next, context) -> context.ran2 = true ; next context
        com3 = (next, context) -> context.ran3 = true ; next context
        result = builder.pipeline com1, com2, com3
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assertSuccess result
        assert.equal ctx.ran1, true
        assert.equal ctx.ran2, true
        assert.equal ctx.ran3, true

  describe 'test array is cloned in chain', ->

    it 'should be unaffected by altering array after build', ->
      ctx = ran: false
      array = []
      result = builder.chain array
      assertSuccess result, ['chain']
      array.push (context) -> context.ran = true
      result = result.chain ctx
      assertSuccess result
      assert.equal ctx.ran, false

  describe 'test array is cloned in pipeline', ->

    it 'should be unaffected by altering array after build', ->
      ctx = ran1: false, ran2: false
      com1 = (next, context) -> context.ran1 = true ; next context
      com2 = (context) -> context.ran2 = true
      array = [com1]
      result = builder.pipeline array
      assertSuccess result, ['pipeline']
      array.push com2
      result = result.pipeline ctx
      assertSuccess result
      assert.equal ctx.ran1, true
      assert.equal ctx.ran2, false

  describe 'test stopping chain with false return', ->

    it 'should stop chain and return', ->
      ctx =
        ran: false
        ran2: false
      com1 = (context) -> context.ran = true ; return false
      com2 = (context) -> context.ran2 = true
      result = builder.chain [com1, com2]
      assertSuccess result, ['chain']
      result = result.chain ctx
      assert.equal ctx.ran, true, 'com1 should set `ran` to true'
      assert.equal ctx.ran2, false, 'com2 should NOT run, ran2 should be false'
      assertError result, [],
        error:'received false'
        type:'chaining'

  describe 'test try-catch by throwing an error', ->

    it 'error should stop chain and be in result', ->
      ctx = com2: false
      com1 = -> throw new Error 'test error'
      com2 = (context) -> context.com2 = true
      result = builder.chain [com1]
      assertSuccess result, ['chain']
      result = result.chain ctx
      assert.equal ctx.com2, false
      assertError result, [],
        error:'chain function threw error'
        type:'caught'

    it 'error should stop pipeline and be in result', ->
      ctx = com2: false
      com1 = -> throw new Error 'test error'
      com2 = (next, context) -> context.com2 = true ; next context
      result = builder.pipeline [com1]
      assertSuccess result, ['pipeline']
      result = result.pipeline ctx
      assert.equal ctx.com2, false
      assertError result, [],
        error:'chain function threw error'
        type:'caught'

  describe 'test context', ->

    describe 'test adding value to context', ->

      it 'should be available to next command in chain', ->
        ctx = {}
        com1 = (context) -> context.add = 'added'
        com2 = (context) -> if context?.add? then context.seen = true
        result = builder.chain [com1, com2]
        assertSuccess result, ['chain']
        result = result.chain ctx
        assert.equal result?, true, 'result should exist'
        assert.equal ctx.add, 'added'
        assert.equal ctx.seen, true

      it 'should be available to next command in pipeline', ->
        ctx = {}
        com1 = (next, context) -> context.add = 'added' ; next context
        com2 = (next, context) ->
          if context?.add? then context.seen = true
          next context
        result = builder.pipeline [com1, com2]
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assertSuccess result
        assert.equal ctx.seen, true
        assert.equal ctx.add, 'added'

    describe 'test not passing a context to chain', ->

      it 'should have an empty object context', ->
        test = ran: false, context: false
        com1 = (context) ->
          test.ran = true
          if context? then test.context = true
        result = builder.chain [com1]
        assertSuccess result, ['chain']
        result = result.chain()
        assertSuccess result
        assert.equal test.ran, true
        assert.equal test.context, true

    describe 'test not passing a context to pipeline', ->

      it 'should have an empty object context', ->
        test = ran: false, context: false
        com1 = (next, context) ->
          test.ran = true
          if context? then test.context = true
          next context
        result = builder.pipeline [com1]
        assertSuccess result, ['pipeline']
        result = result.pipeline()
        assertSuccess result
        assert.equal test.ran, true
        assert.equal test.context, true

  describe 'test applying context as *this*', ->

    describe 'test accessing context value from this', ->

      it 'should be available from this in chain', ->
        ctx = found:false
        com1 = -> this.found = true
        result = builder.chain [ com1 ]
        assertSuccess result, ['chain']
        result = result.chain ctx
        assertSuccess result
        assert.equal ctx.found, true

      it 'should be available from this in pipeline', ->
        ctx = found:false
        com1 = (next, context) -> this.found = true ; next context
        result = builder.pipeline [ com1 ]
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assert.equal ctx.found, true

    describe 'test adding value to *this*', ->

      it 'should be available to next command in chain', ->
        ctx = {}
        com1 = () -> this.add = 'added'
        com2 = () -> if this?.add? then this.seen = true
        result = builder.chain [com1, com2]
        assertSuccess result, ['chain']
        result = result.chain ctx
        assertSuccess result
        assert.equal ctx.add, 'added'
        assert.equal ctx.seen, true

      it 'should be available to next command in pipeline', ->
        ctx = {}
        com1 = (next, context) -> this.add = 'added' ; next context
        com2 = (next, context) ->
          if this?.add? then this.seen = true
          next context
        result = builder.pipeline [com1, com2]
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assert.equal ctx.seen, true
        assert.equal ctx.add, 'added'

    describe 'test calling next with *this*', ->

      it 'should work same as context', ->
        ctx = changed:false, found:false
        com1 = (next, context) -> context.changed = true ; next this
        com2 = (next, context) ->
          if context.changed then context.found = true
          next context
        result = builder.pipeline [ com1, com2 ]
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assert.equal ctx.found, true

  describe 'test optional *this* on function', ->

    describe 'test for chain', ->

      it 'should make *this* equal to object in options.this', ->
        thiss = accessed:false
        options = this: thiss
        ctx = available:false
        com1 = (sharedContext) ->
          this.accessed = true
          sharedContext.available = true
        com1.options = options
        result = builder.chain [ com1 ]
        assertSuccess result, ['chain']
        result = result.chain ctx
        assert.equal ctx.available, true
        assert.equal thiss.accessed, true

    describe 'test for pipeline', ->

      it 'should make *this* equal to object in options.this', ->
        thiss = accessed:false
        options = this: thiss
        ctx = available:false
        com1 = (next, sharedContext) ->
          this.accessed = true
          sharedContext.available = true
          next sharedContext
        com1.options = options
        result = builder.pipeline [ com1 ]
        assertSuccess result, ['pipeline']
        result = result.pipeline ctx
        assert.equal ctx.available, true, 'ctx.available should be true'
        assert.equal thiss.accessed, true, 'thiss.accessed should be true'
