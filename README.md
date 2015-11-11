# chain-builder
[![Build Status](https://travis-ci.org/elidoran/chain-builder.svg?branch=master)](https://travis-ci.org/elidoran/chain-builder)
[![Dependency Status](https://gemnasium.com/elidoran/chain-builder.png)](https://gemnasium.com/elidoran/chain-builder)
[![npm version](https://badge.fury.io/js/chain-builder.svg)](http://badge.fury.io/js/chain-builder)

Manage an array of functions and execute them in a series with a variety of flows.

Some of the features:

1. "chain of command" - call functions in series
2. "waterfall" - uses a `context` object which is provided to each function in sequence. accepts one for the initial call (unlike `async.waterfall()`). It's different than providing the output to the next function a input, however, it can achieve the same results, and, it's possible to provide an entirely new object to each subsequent function.
3. "pipeline/filter" - a series of functions which call the next one, can override the input, can do work after the later functions return
4. accepts a `done` callback and sends the error or result to it
5. can *pause* the chain and use a callback to *resume* it; which supports asynchronous execution
6. can *stop* the chain early as a success; accepts a `reason`
7. can *fail* the chain execution as an error; accepts a `reason`
8. the context provided to each function is also the *this*, unless overridden via an option
9. the *this* can be overridden per function via an options object on the function (better than bind because it uses a single `call()` instead of two)
10. can override the context used by the next function (which can choose to pass that one on, or, allow the default context to be restored), and, can override the default context used by all future functions and is returned in the final result.
11. is an *EventEmitter* with events for: start, pause, resume, stop, fail, done.

## Install

    npm install chain-builder --save


## Usage: Simple
[More Usage](#usage)

```coffeescript
buildChain = require 'chain-builder'

# for simple chains there's no need to use either function params, just *this*
fn1 = -> this.message += ' there'  # message = 'hello there'
fn2 = -> this.message += ', Bob'   # message = 'hello there, Bob'
fn3 = -> console.log this.message  # writes full message to console

chain = buildChain()
chain.add fn1, fn2, fn3
# could already be in an array like:
# chain.add [fn1, fn2, fn3]

# a mutable context object given to each fn in the chain
context = message:'hello'

result = chain.run context
# prints 'hello there, Bob'
# result has information depending on what occurred, this simple one is: {
#   result:true
#   context: { message:'hello there, Bob' }
# }
```

## Execution Control

By default, each function will be called in sequence and the `this` will be the `context` object. This supports a basic 'chain of command' with functions having no params using the `this` to access the context.

Each function is called with the parameters `(control, context)`. The *control* object is specific to each call to `chain.run()`. The *context* object is either an empty object by default, or, the context specified to the `chain.run()` call.

The `control` parameter replaces the usual `next` and allows changing the execution flow in multiple ways.

1. pause - pauses execution until the returned resume callback is called
2. stop - ends execution as a success
3. fail - ends execution as an error
4. context - override context for next function, or all functions

Also, a `done` callback may be provided to the `chain.run()` call. It will be called with `(error, results)` when the chain is completed via any of the various flows.


## Execution Flow Styles

A "chain of command" example is in the [simple example](#usage-simple). Each function is called in sequence.

A "pipeline/filter" may call `result = control.next()` to execute the later functions, then, do more work after that, and finally return the received `result` (or their own result, if desired). This allows it to do work *after* the other functions were called. Note, this assumes a synchronous execution through the entire chain afterwards. If a later function uses `control.pause()` then a result containing the paused info will be returned to `control.next()`.

Asynchronous steps are achievable using `resume = control.pause()`. Once called, the chain will wait to continue execution until the *resume* function is called. The *pause* function accepts a `reason` value which will stored in the *control*. Note, the current result will be returned back through the synchronous executions and return a final result containing the `paused` information.

Sometimes it's helpful to end a chain early because its work is complete without calling the later functions. Use `control.stop()` to do that. It will return a result back through the synchronous executions. The *stop* function accepts a `reason` value which will be part of the returned results.

It's possible to end the chain because an error has occurred with `control.fail()`. It will return a result back through the synchronous executions. The *fail* function accepts a `reason` value which will be part of the returned results.


## Use Context or This ?

You may choose to use either. It is up to your own preferred style. It is possible to customize the this via options on the function, so, in that instance the *this* will be different than the *context* so both can be used.


## Considerations

1. `chain.add()` - passing a single function, without an array, will be treated as an array with a single function
2. `chain.add()` - passing multiple function arguments (not an array) will be treated as an array of those functions
3. the array can be changed which will affect any currently running chain executions (async) when they attempt to retrieve the next function to call
4. be careful to ensure [advanced context manipulations](#advanced-contexts) don't break others' functions

## Usage

[JavaScript Usage Example](#javascript-style-usage)

### Simple

This is already above at [Usage: Simple](#usage-simple)


### Stopping Chain

You may stop a chain's execution in two ways:

1. `control.stop()` - means a successful conclusion was reached
2. `control.fail()` - means a failure prevents the chain from continuing

Each of these stores the same information into the *control*:

1. *reason* - the reason value provided to the function call
2. *index* - the index in the array of the function which called stop/fail
3. *fn* - the function which called stop/fail

Here's an example of using `control.stop()`:

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> this.done = true
fn2 = (control) -> if this.done then control.stop 'we are done'
fn3 = -> console.log 'I won\'t run'

chain = buildChain array:[ fn1, fn2 ]

result = chain.run done:false
# fn3 will never run.
# result is: {
#   result: true
#   stopped:{ reason:'we are done', index:1, fn:fn2}
# }
```

Here's an example of using `control.fail()`:

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> this.problem = true
fn2 = (control) -> if this.problem then control.fail 'there is a problem'
fn3 = -> console.log 'I won\'t run'

chain = buildChain array:[ fn1, fn2 ]

result = chain.run problem:false
# fn3 will never run.
# result is: {
#   result: false
#   failed:{ reason:'there is a problem', index:1, fn:fn2}
# }
```

### Use Context to Pass on a Value

Shown many times above already, the context object is available to each function. Here is an explicit example of doing so:

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> this.give = 'high 5'
fn2 = -> if this.give is 'high 5' then 'cheer'

chain = buildChain array:[ fn1, fn2 ]

result = chain.run()   # will use an empty object as context
# fn2 will, uh, *cheer*
```

### Throw Error

What if a function throws an error?

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> throw new Error 'my bad'

chain = buildChain array:[fn1]

result = chain.run()

# fn1 will throw an error
# chain will catch it, end the chain, and include it in the result
# result is {
#   context: {}
#   error: [Error: my bad] # value is the Error instance's string representation
# }
```

## Advanced Contexts

There are two "contexts" which have been the *same* in all the above examples.
It is possible to make them different for advanced use. Please, be careful :)

### The two contexts

1. **shared context** : the second argument passed to each function

```coffeescript
    (control, context) -> console.log '<-- that context'
```

2. **this context** : the *this* while each function is executing

```coffeescript
    (control, context) -> console.log 'that context-->' + this.someProperty
```

### How to specify the `this` context

Provide an options object on the function which includes a `this` property. When you do, the `this` will be set as the *this* for the function.

```coffeescript
buildChain = require 'chain-builder'

specificThis = some:'special this'

fn = (control, sharedContext) ->
  console.log '*this* is specificThis. some=', this.some
  console.log 'sharedContext is a shared ', sharedContext.shared

fn.options = this:specificThis

chain = buildChain array:[fn]

chain.run shared:'object'

# prints:
#   *this* is specificThis. some=special this
#   sharedContext is a shared object
```

### Why not use `bind()` ?

When using `bind()` it wraps the function with another function which calls it with the `this` context specified. That means to call the function it's now two function calls.

When specifying the `this` via an option it is used in the `fn.call()` as an argument. It doesn't make more work.

See:

```coffeescript
# we'll use bind on this one
fn1Original = -> console.log this.message  # that's a one and a capital O
fn1This = message:'I am two calls'
fn1Bound = fn1.bind fn1This

# we'll use the options.this on this one
fn2 = -> console.log this.message
fn2This = message:'I am one call'
fn2.options = this:specialThis

chain = buildChain()
chain.add fn1Bound, fn2
chain.run()

# for fn1, it is equivalent to this:
# the chain will call the bound function like this:
fn1Bound.call context, control, context
# when called, the bound function will use apply to call the original
# function with the fn1This
fn1Bound = -> fn1Original.apply fn1This, Array.prototype.slice.call arguments
# so, the first call specifies a *this* which will be overridden by the bound function.

# for fn2, it is simpler because it passes the special this to the first
# *call*. So, no second call. No need for bind().
fn2.call fn2.options.this, control, context
```

Note, using `control.context()` overrides the *context* provided to the next function. Using `fn.options.this` overrides the *this*. This means, it's possible to completely change what a function receives as context and this and have a different view than all other functions called in a chain.

### How to Control the Shared Context

The *shared context* can be manipulated in multiple ways.

When calling `chain.run()` you may specify a context as an option: `chain.run context:{}`. See more in the [chain.run() API](#api-chainrun).

Once a chain is running you may alter the context used both *permanently* and *impermanently* using the `chain.context()` function. That function will also execute the next function in the chain.

1. `control.context newContext` - this will override the context used by the next function called *only*. the default context is unaffected and will be used by functions after the next one. A function may choose to pass on this *impermanently* overridden context by doing an override (`control.context context`) again and passing the context to it.
2. `control.context newContext, true` - the *true* means it's a *permanent* override. It will set the default context used for all subsequent functions. Also, the default context is supplied in the final results, so, a permanently overridden context will then be in the final results.

Here is an example of an impermanent override:

```coffeescript
buildChain = require 'chain-builder'

defaultContext = {}
overrideContext = {}

fn1 = -> this.fn1 = 'this'

fn2 = (control, context) -> context.fn2 = 'context'

fn3 = (control) ->
  this.fn3 = 'this'
  control.context overrideContext

fn4 = (control, context) ->
  this.fn4 = 'this'
  context.fn4 += ', context'

fn5 = (control, context) ->
  this.fn5 = 'this'
  context.fn5 += ', context'

chain = buildChain array:[fn1, fn2, fn3, fn4, fn5]
result = chain.run context:defaultContext
result = # {
#   result:true
#   context: {        # this is the default context, missing `fn4`
#     fn1 : 'this'
#     fn2 : 'context'
#     fn3 : 'this'
#     fn5 : 'this, context'
#   }
# }
overrideContext = # {
#   fn4 : 'this, context'
# }
```

Only `fn4` received the `overrideContext`.

Here is an example of a permanent override:

```coffeescript
buildChain = require 'chain-builder'

defaultContext = {}
overrideContext = {}

fn1 = -> this.fn1 = 'this'

fn2 = (_, context) -> context.fn2 = 'context'

fn3 = (control) ->
  this.fn3 = 'this'
  control.context overrideContext, true    # <-- the `true` makes it permanent

fn4 = (control, context) ->
  this.fn4 = 'this'
  context.fn4 += ', context'

fn5 = (control, context) ->
  this.fn5 = 'this'
  context.fn5 += ', context'

chain = buildChain array:[fn1, fn2, fn3, fn4, fn5]
result = chain.run context:defaultContext
result = # {
#   result:true
#   context: {   <-- this is the overrideContext
#     fn4 : 'this, context'
#     fn5 : 'this, context'
#   }
# }
defaultContext = # {  <-- wasn't returned in final result, doesn't have fn4/fn5
  #     fn1 : 'this'
  #     fn2 : 'context'
  #     fn3 : 'this'
# }
overrideContext = # {  <-- was in final result, contains fn's after the override
  #     fn4 : 'this, context'
  #     fn5 : 'this, context'
# }
```

## Usage: Pipeline/Filter Style

This style allows performing work after the later functions return. It relies on synchronous execution.

Here is an example:

```coffeescript
buildChain = require 'chain-builder'

fn1 = (control) ->
  # provide some value into the context from some operation
  this.value = doSomeOperation()

  # call the later functions which will do something with the value
  result = control.next()

  # check for an error before doing more work
  unless result?.error?

    # do something after the rest of the chain has run
    this.anotherValue = someOtherOperation this.valueFromLaterFunctions

  # then let the function return the result it received
  # Note, this can be changed as well, or, not returned at all.
  return result

fn2 = () -> this.valueFromLaterFunctions = someOperationOfItsOwn()

chain = buildChain array:[fn1, fn2]
result = chain.run()
result = # {
#   value: 'something'                        <-- fn1 put this into context
#   valueFromLaterFunctions: 'something more' <-- fn2 put this into context
#   anotherValue: 'something else'            <-- fn1 did this *after* fn2 ran
# }
```


## Usage: Asynchronous

Although the above examples show synchronous execution it is possible to run a chain asynchronously using the `control.pause()` function.

An example:

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> console.log this.message1

fn2 = (control, context) ->
  console.log this.message2
  resume = control.pause()  # returns a function to call to resume execution
  setTimeout resume, 1000 # schedule resume in a second
  return # return nothing

fn3 = () -> console.log this.message3

chain = buildChain array:[fn1, fn2, fn3]
result = chain.run
  message1: 'in fn1'
  message2: 'in fn2 and pausing'
  message3: 'resumed and in fn3'

# this will be printed before the chain is resumed and fn3 is run
console.log 'back from chain.run()'

# the console will print:
#   in fn1
#   in fn2 and pausing
#   back from chain.run()
#   resumed and in fn3
```

If your code calls the `resume` function then it will receive the final result returned by `resume`.

Using `setTimeout()` and other similar functions will make extra work to get that. So, you may specify a `done` callback to `chain.run()` to receive the final results, or the error, when a chain run completes.

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> console.log this.message1

fn2 = (control, context) ->
  console.log this.message2
  resume = control.pause()  # returns a function to call to resume execution
  setTimeout resume, 1000 # schedule resume in a second
  return # return nothing

fn3 = () -> console.log this.message3

chain = buildChain array:[fn1, fn2, fn3]

# specify a done callback as part of the options object which will be run when
# the chain run is finished
result = chain.run done:(error, results) ->
  # the results object is the same as what chain.run() returns when synchronous
  console.log 'in done'

# this will be printed before the chain is resumed and fn3 is run, and,
# before the done callback is called, of course
console.log 'back from chain.run()'

# the console will print:
#   in fn1
#   in fn2 and pausing
#   back from chain.run()
#   resumed and in fn3
#   in done
```


## API

TODO: Complete API specifying each function available

### API: buildChain()

### API: chain.add(fn[, fn]*)

May also provide an array as an argument.

### API: chain.remove(fn[, fn]*)

May also provide an array as an argument.

### API: chain.run(options:Object[, done:Function])

### API: control.next()

### API: control.context(Object)

### API: control.pause(reason:String)

### API: control.stop(reason:String)

### API: control.fail(reason:String)


# JavaScript Style Usage

[CoffeeScript Usage](#usage)

## JS Usage

TODO: complete all JS code examples for each CS example above.

### JS Simple

```javascript
buildChain = require('chain-builder');

fn1 = function() { this.message += ' there'; }; // message = 'hello there'
// context = this  so, the below is equivalent
//fn1 function(control, context) { context.message += ' there'; };
fn2 = function() { this.message += ', Bob'; };  // message = 'hello there, Bob'
fn3 = function() { console.log(this.message); };// writes full message to console

chain = buildChain();
chain.add(fn1, fn2, fn2);
// could already be in an array like:
// chain.add([fn1, fn2, fn3])

// a mutable object given to each fn in the chain
context = {message:'hello'}

result = chain.run(context);
// prints 'hello there, Bob' to the console
// result has information depending on what occurred, this simple one is: {
//   result:true,
//   context: { message:'hello there, Bob' }
// }
```

## MIT License
