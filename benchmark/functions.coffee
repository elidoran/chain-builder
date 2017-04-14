module.exports =
  empty: ->
  repeat: (count, fn) ->
    array = new Array count
    array[i] = fn for i in [0...count]
    return array
  increment: -> @n++
  incrementBy: (increment) -> -> @n += increment
  pause: (reason) -> (control) -> control.pause reason
  stop : (reason) -> (control) -> control.stop reason
  fail : (reason) -> (control) -> control.fail reason
  
