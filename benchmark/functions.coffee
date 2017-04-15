module.exports =
  empty: ->
  repeat: (count, fn) ->
    array = new Array count
    array[i] = fn for i in [0...count]
    return array
  increment: -> @n++
  incrementMany: -> @a++ ; @b++ ; @c++ ; @d++ ; @e++ ; @f++ ; @g++
  incrementBy: (increment) -> -> @n += increment
  context: (context) -> (control) -> control.context context ? some: 'context'
  contextPermanent: (context) -> (control) -> control.context context ? {some: 'context'}, true
  next : (context) -> (control) -> control.next context ? some: 'context'
  nextPermanent: (context) -> (control) -> control.next context ? {some:'context'}, true
  pause: (reason) -> (control) -> control.pause reason
  stop : (reason) -> (control) -> control.stop reason
  fail : (reason) -> (control) -> control.fail reason
  id   : (id) ->
    fn = ->
    fn.options = id:id
    return fn
  options: (options) ->
    fn = ->
    fn.options = options
    return fn
