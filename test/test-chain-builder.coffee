assert = require 'assert'
builder = require '../index'

describe 'test building chains', ->
  before ->

  beforeEach 'placeholder', ->

  describe 'test empty chain', ->

    it 'should return an noop function', ->
      fn = builder.chain []
      assert.equal ''+fn, 'function () {}'

  describe 'test single input to chain', ->

    it 'should give a chain for the single function'#, ->
    #  com = (context) ->
    #  fn = builder.chain [com]

  describe 'test stopping chain with falsey return', ->

    it 'should stop chain and return'

  describe 'test adding value to context', ->

    it 'should be available to next command'
