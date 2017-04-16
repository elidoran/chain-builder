assert = require 'assert'

optimize = require '@optimal/fn'

buildChain = require '../lib/index.coffee'
getOptions = require '../lib/get-options.coffee'

describe.only 'verify optimizability', ->

  describe 'of builder', ->

    it 'with one fn arg', ->

      result = optimize buildChain, null, [->]
      assert.equal result.optimized, true


    it 'with two fn args', ->

      result = optimize buildChain, null, [(->), (->)]
      assert.equal result.optimized, true


    it 'with three fn args', ->

      result = optimize buildChain, null, [(->), (->), (->)]
      assert.equal result.optimized, true


    it 'with array of one fn as arg', ->

      result = optimize buildChain, null, [array:[(->)]]
      assert.equal result.optimized, true


    it 'with array of three fn\'s arg', ->

      result = optimize buildChain, null, [array:[(->), (->), (->)]]
      assert.equal result.optimized, true


    it 'with no args', ->

      result = optimize buildChain, null, []
      assert.equal result.optimized, true


  describe 'of getOptions', ->

    it 'with one fn arg', ->

      result = optimize getOptions, null, [->]


    it 'with two fn args', ->

      result = optimize getOptions, null, [(->), (->)]


    it 'with three fn args', ->

      result = optimize getOptions, null, [(->), (->), (->)]


    it 'with array of fn\'s', ->

      result = optimize getOptions, null, [ array: [(->), (->), (->)] ]


    it 'with object arg with base/props', ->

      result = optimize getOptions, null, [ base:{}, props:{value:1} ]


    it 'with emtpy object arg', ->

      result = optimize getOptions, null, [ {} ]
