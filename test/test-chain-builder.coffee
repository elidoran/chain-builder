assert = require 'assert'
builder = require '../index'

describe 'test building chains', ->
  before ->

  beforeEach 'placeholder', ->

  describe 'test empty chain', ->

    it 'should return an noop function', ->
      fn = builder.chain []
      assert.equal ''+fn, -> true

  describe 'test single input to chain', ->

    it 'should give a chain for the single function', ->
      context =
        ran: false
      com = (context) -> context.ran = true
      fn = builder.chain [com]
      result = fn context
      assert.equal context.ran, true
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
