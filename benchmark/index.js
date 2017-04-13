var inspect, pad, Benchmark, suite, revised, original, methods, results, useDelta, columns, row, oldOps, INVALID, NA, inputs, equal, format

require('console.table')
format = require('comma-number')
equal = require('deep-eql')
inspect = require('util').inspect
pad = require('pad')
Benchmark = require('benchmark')
suite = new Benchmark.Suite
revised = require('../lib/')
original = require('./original')
methods = [original, revised]
results = []
useDelta = process.argv.indexOf('--delta') > -1
columns = (methods.length * (useDelta ? 2 : 1)) + 2
row = 0
oldOps = -1
INVALID = '!    invalid'
NA = '  N/A'

inputs = [

  [
    'simple',
    [
      { // context
        some: 'test',
      },
      { // build options
        array: [ function() {} ]
      },
    ],
    {
      result: true,
      context: {
        some: 'test',
      },
      chain: null
    }
  ],

  [
    'many functions',
    [
      { // context
        some: 'test',
      },
      { // build options
        array: [ function(){ this.n = 0}, function(){this.n++}, function(){this.n+=2}, function(){this.n+=3}, function(){this.n+=4}, function(){this.n+=5}, function(){this.n+=6},
          function(){this.n+=7},
          function(){this.n+=8}, function(){this.n+=9}, function(){this.n+=10}, function(){this.n+=11}, function(){this.n+=12}, function(){this.n+=13}, function(){this.n+=14}, function(){this.n+=15},
          function(){this.n+=16}, function(){this.n+=17}, function(){this.n+=18}, function(){this.n+=19}, function(){this.n+=20}, function(){this.n+=21}, function(){this.n+=22}, function(){this.n+=23},
          function(){this.n+=24}
        ]
      },
    ],
    {
      result: true,
      context: {
        some: 'test',
        n: 300
      },
      chain: null
    }
  ],

  [
    'stopped',
    [
      { // context
        some: 'test',
      },
      { // build options
        array: [ function(control) { return control.stop('success')}, ]
      },
    ],
    {
      result: true,
      context: {
        some: 'test',
      },
      chain: null,
      stopped: {
        reason: 'success',
        index: 0,
        fn: null
      }
    }
  ],

  [
    'paused',
    [
      { // context
        some: 'test',
      },
      { // build options
        array: [ function(control) { return control.stop('testing')}, ]
      },
    ],
    {
      result: true,
      context: {
        some: 'test',
      },
      chain: null,
      stopped: {
        reason: 'testing',
        index: 0,
        fn: null
      }
    }
  ],

  [
    'failed',
    [
      { // context
        some: 'test',
      },
      { // build options
        array: [ function(control) { return control.fail('testing')}, ]
      },
    ],
    {
      result: false,
      context: {
        some: 'test',
      },
      chain: null,
      failed: {
        reason: 'testing',
        index: 0,
        fn: null
      }
    }
  ],


]

Benchmark.options.initCount  = 20
Benchmark.options.minSamples = 20

function run(fn, input) {
  chain = fn(input[1])
  context = { context: input[0] }
  return function() {
    var result
    result = chain.run(context)
    result.chain = null
    if (result.stopped) result.stopped.fn = null
    if (result.paused) result.paused.fn = null
    if (result.failed) result.failed.fn = null
    return result
  }
}

for (var i = 0, end = inputs.length; i < end; i++) {
  var input, name, rowResult, fn

  name = inputs[i][0]
  input = inputs[i][1]
  answer = inputs[i][2]
  // console.log('input', name, input, answer)
  name = pad(20, name)

  rowResult = {
    name: name,
    old: { info: null, valid: false },
    new: { info: null, valid: false }
  }

  // start out with an object containing the info.
  // the onCycle event will replace it with a data array
  results.push(rowResult)

  fn = run(methods[0], input)

  // test if function produces answer.
  if (equal(fn(), answer)) {
    rowResult.old.valid = true
    suite.add(name, fn)
  }

  fn = run(methods[1], input)
  console.log('result:', fn())
  if (equal(fn(), answer)) {
    rowResult.new.valid = true
    suite.add(name, fn)
  }

  // if they're both invalid then we have to handle it right now
  if (rowResult.old.valid === false && rowResult.new.valid === false) {
    results[results.length - 1] = resultArray(rowResult)
  }
}

if (results && results.length === 0) {
  return console.error('no tests added')
}

function filterInfo(info) {
  return { hz: info.hz, rme: info.stats.rme }
}

function formatOps(info) {
  var fixed, formatted
  fixed     = info.hz.toFixed(0)
  formatted = format(fixed)
  return pad(12, formatted)
}

function formatDelta(info) {
  var fixed, decorated
  fixed     = info.rme.toFixed(1)
  decorated = '+-' + fixed + '%'
  return pad(6, decorated)
}

function formatDiff(oldResult, newResult) {
  var diff, percent, decorated
  if (oldResult.valid && newResult.valid) {
    diff    = (newResult.info.hz - oldResult.info.hz)
    percent = (diff / oldResult.info.hz) * 100
    decorated = percent.toFixed(0) + '%'
    return pad(5, decorated)
  } else {
    return NA
  }
}

function resultArray(result) {
  var array, newIndex

  if (useDelta) {
    array = [ result.name, null, null, null, null, null ]

    array[2] = (result.old.valid) ? formatDelta(result.old.info) : NA
    array[4] = (result.new.valid) ? formatDelta(result.new.info) : NA

    newIndex = 3
  } else {
    array = [ result.name, null, null, null ]
    newIndex = 2
  }

  array[1] = (result.old.valid) ? formatOps(result.old.info) : INVALID
  array[newIndex] = (result.new.valid) ? formatOps(result.new.info) : INVALID
  array[array.length - 1] = formatDiff(result.old, result.new)

  return array
}

suite.on('cycle', function(event) {
  var it, result, which

  it = event.target
  result = results[row]

  // if all methods produced invalid results then this `result` will already be
  // an array. so, skip until we find a result row which is *not* an array.
  // that's the one which corresponds to the current cycle result.
  while (Array.isArray(result)) {
    row++
    result = results[row]
  }

  if (result.old == null)
    console.log('result is missing `old`:',result)

  which = (result.old.info == null && result.old.valid) ? 'old' : 'new'

  console.log(which, 'completed', it.name)

  if (which === 'new') {
    result.new.info = filterInfo(it)
    results[row] = resultArray(result)
    row++
  } else {
    result.old.info = filterInfo(it)
  }
})

suite.on('complete', function() {
  var headers
  headers = ['     input', '     old     ', '     new     ', '+']
  if (useDelta) {
    headers.splice(2, 0, 'delta1')
    headers.splice(4, 0, 'delta2')
  }
  console.log()
  console.table(headers, results)
})

suite.run({
  async: false
})
