assert = require 'assert'
builder = require '../index'

describe 'test building chains/pipelines', ->
  #before ->
  #beforeEach '', ->

  describe 'test passing bad values to chain/pipeline', ->

    describe 'test null to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain null

    describe 'test null to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline null

    describe 'test undefined to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain undefined

    describe 'test undefined to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline undefined

    describe 'test undefined in array to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain [undefined]

    describe 'test undefined in array to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline [undefined]

    describe 'test null in array to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain [null]

    describe 'test null in array to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline [null]

    describe 'test Object in array to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain [{}]

    describe 'test Object in array to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline [{}]

    describe 'test string in array to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain ['string']

    describe 'test string in array to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline ['string']

    describe 'test number in array to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain [-1]

    describe 'test number in array to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline [-1]

    describe 'test Date in array to chain', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.chain [new Date()]

    describe 'test Date in array to pipeline', ->

      it 'should throw error', -> # TODO: use `had` instead
        assert.throws ->
          builder.pipeline [new Date()]

    # TODO: check error message above to ensure index is 0 and value is reported
    # TODO: make more of those which have the invalid value later in the array

  describe 'test successful runs', ->

    describe 'test empty chain', ->

      it 'should return an noop function', ->
        fn = builder.chain []
        noop = /function\s?\(\)\s?{\n\s*return true;\n\s*}/
        assert.equal noop.test(''+fn), true

    describe 'test empty pipeline', ->

      it 'should return an noop function', ->
        fn = builder.pipeline []

    describe 'test single input to chain', ->

      it 'should give a chain for the single function', ->
        context =
          ran: false
        com = (context) -> context.ran = true
        fn = builder.chain [com]
        result = fn context
        assert.equal context.ran, true
        assert.equal result, true

    describe 'test single input to pipeline', ->

      it 'should give a pipeline for the single function', ->
        context =
          ran: false
        com = (context, next) -> context.ran = true ; next context
        fn = builder.pipeline [com]
        result = fn context
        assert.equal context.ran, true
        assert.equal result, true

    describe 'test passing function to chain', ->

      it 'should give a chain for the single function', ->
        context =
          ran: false
        com = (context) -> context.ran = true
        fn = builder.chain com
        result = fn context
        assert.equal context.ran, true
        assert.equal result, true

    describe 'test passing function to pipeline', ->

      it 'should give a pipeline for the single function', ->
        context =
          ran: false
        com = (context, next) -> context.ran = true ; next context
        fn = builder.pipeline com
        result = fn context
        assert.equal context.ran, true
        assert.equal result, true

  describe 'test array is cloned in chain', ->

    it 'should be unaffected by altering array after build', ->
      context = ran: false
      array = []
      fn = builder.chain array
      array.push (context) -> context.ran = true
      result = fn context
      assert.equal context.ran, false
      assert.equal result, true

  describe 'test array is cloned in pipeline', ->

    it 'should be unaffected by altering array after build', ->
      context = ran1: false, ran2: false
      com1 = (context) -> context.ran1 = true
      com2 = (context) -> context.ran2 = true
      array = [com1]
      fn = builder.pipeline array
      array.push com2
      result = fn context
      assert.equal context.ran1, true
      assert.equal context.ran2, false
      assert.equal result, true

  describe 'test stopping chain with false return', ->

    it 'should stop chain and return', ->
      context =
        ran: false
        ran2: false
      com1 = (context) -> context.ran = true ; return false
      com2 = (context) -> context.ran2 = true
      fn = builder.chain [com1, com2]
      result = fn context
      assert.equal context.ran, true, 'com1 should set `ran` to true'
      assert.equal context.ran2, false, 'com2 should NOT run, ran2 should be false'
      assert.equal result, false, 'chain result should be false'

  describe 'test adding value to context', ->

    it 'should be available to next command', ->
      context = {}
      com1 = (context) -> context.add = 'added'
      com2 = (context) -> if context?.add? then context.seen = true
      fn = builder.chain [com1, com2]
      result = fn context
      assert.equal result, true
      assert.equal context.add, 'added'
      assert.equal context.seen, true

  describe 'test try-catch by throwing an error', ->

    it 'error should stop chain and be in context', ->
      context = com2: false
      com1 = -> throw new Error 'test error'
      com2 = (context) -> context.com2 = true
      fn = builder.chain [com1]
      result = fn context
      assert.equal result, false
      assert.equal context.chainError?, true
      assert.equal context.com2, false
