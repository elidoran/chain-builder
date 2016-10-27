# chain-builder
[![Build Status](https://travis-ci.org/elidoran/chain-builder.svg?branch=master)](https://travis-ci.org/elidoran/chain-builder)
[![Dependency Status](https://gemnasium.com/elidoran/chain-builder.png)](https://gemnasium.com/elidoran/chain-builder)
[![npm version](https://badge.fury.io/js/chain-builder.svg)](http://badge.fury.io/js/chain-builder)

Manage an array of functions and execute them in a series with a variety of flows.

Some of the features:

1. "chain of command" - call functions in series
2. the simplest use case is still simple: supply an array of functions, and they'll be called in sequence.
3. complex things are also simple such as providing your own context or altering it during an execution, overriding the `this` without using `bind()`, and more.
4. "waterfall" - uses a `context` object which is provided to each function in sequence. accepts one for the initial call (unlike `async.waterfall()`). It's different than providing the output to the next function as input, however, it can achieve the same results, and, it's possible to provide an entirely new object to each subsequent function.
5. "pipeline/filter" - a series of functions which call the next one, can override the input, can do work after the later functions return
6. accepts a `done` callback and sends the error or result to it
7. can *pause* the chain and use a callback to *resume* it; which supports asynchronous execution
8. can *stop* the chain early as a success; accepts a `reason`
9. can *fail* the chain execution as an error; accepts a `reason`
10. the context provided to each function is also the *this*, unless overridden via an option
11. the *this* can be overridden per function via an options object on the function (better than bind because it uses a single `call()` instead of two)
12. can override the context used by the next function (which can choose to pass that one on, or, allow the default context to be restored), and, can override the default context used by all future functions and is returned in the final result.
13. can `disable()` and `enable()` the whole chain, or a single function by its index/id/self, or a selection of functions chosen by a function you provide.
14. can `remove()` a function by its index/id/self, or using the `select()` function, or via `control.remove()` during a chain execution.
15. is an *EventEmitter* with events for: start, pause, resume, stop, fail, add, remove, disable, enable, and done.

# Install

```
npm install chain-builder --save
```

# Table of Contents (CS)

[[JS5]](http://github.com/elidoran/chain-builder/blob/master/README.md)
[[JS6]](http://github.com/elidoran/chain-builder/blob/master/docs/README-JS6.md)

A. Usage

  1. [Basic](#usage-basic)
  2. [Simple](#usage-simple)
  3. [Complex](#usage-complex)

B. Executing a Chain

  1. [Control](#execution-control)
  2. [Flow Styles](#execution-flow-styles)
  3. [Context or This?](#use-context-or-this)

C. [Examples](#examples)

  1. [Stopping Chain](#stopping-chain)
  2. [Pass on a Value via Context](#use-context-to-pass-on-value)
  3. [Thrown Errors](#thrown-error)
  4. [Pipeline/Filter](#pipelinefilter-style)
  5. [Asynchronous](#asynchronous)

D. [Advanced Contexts](#advanced-contexts)

  1. [Two Contexts](#the-two-contexts)
  2. [How to specify the this context](#how-to-specify-the-this-context)
  3. [Why not use bind()?](#why-not-use-bind)
  4. [Control the Shared Context](#how-to-control-the-shared-context)

E. [API](#api)

  1. [Exported Builder Function](#api-exported-builder-function)
  2. [Chain](#api-chain)

    * [chain.run()](#api-chain-run)
    * [chain.add()](#api-chain-add)
    * [chain.remove()](#api-chain-remove)
    * [chain.disable()](#api-chain-disable)
    * [chain.enable()](#api-chain-enable)
    * [chain.select()](#api-chain-select)

  3. [Control](#api-control)

    * [control.next()](#api-control-next)
    * [control.context()](#api-control-context)
    * [control.pause()](#api-control-pause)
    * [control.stop()](#api-control-stop)
    * [control.fail()](#api-control-fail)
    * [control.disable()](#api-control-disable)
    * [control.remove()](#api-control-remove)
    * [resume()](#api-resume)
    * [resume.callback()](#api-resume-callback)

F. [MIT License](#mit-license)


## Usage: Basic

Here is an extremely basic example to show the basic parts working together.

    buildChain = require 'chain-builder'
    chain = buildChain()

    # you have a function
    fn1 = () -> console.log 'simple'

    # add it. (You can supply it to `buildChain()` as well)
    chain.add fn1

    # run the chain with default options which creates an empty context
    results = chain.run()

    # the results object is:
    results =
      result : true  # means it was a success. no error. no fail().
      context: {}    # the default context is an empty object.
      chain  :       # the chain ...


## Usage: Simple

The most commonly used features:

1. accessing the `context` via function param or `this`
2. reporting an error from inside a function
3. reviewing the final results


Let's make our first function a guardian. it'll check for something and error if it's missing. For that, it needs the first arg, the `control`.

    guard = (control) ->
      # if the 'message' property is missing from the context object
      unless this.message?
        # return a false result with this error message
        control.fail 'missing message'

For simpler functions there's no need to use either function params, use `this`.

    fn1 = () ->
      # the initial `message` value is provided to `chain.run()` below
      this.message += ' there'  # makes `message` = 'Hello there'

    fn2 = () ->
      this.message += ', Bob';   # makes message = 'Hello there, Bob'

    fn3 = () ->
      # writes full message to console
      console.log this.message

    chain = buildChain fn1, fn2, fn3
    # OR: add them after a chain is created
    chain.add fn1, fn2, fn3
    # OR: add them as an array
    chain.add [ fn1, fn2, fn3 ]

    # a mutable context object given to each fn in the chain
    context = message: 'Hello'
    # the options provided to run() may contain a context object to use
    runOptions = context: context
    # run the chain with our context
    result = chain.run runOptions

What it will do:

1. check the existence of the `message` property in the context
2. alter the context's `message` property in fn1 and fn2
3. print 'hello there, Bob' in function fn3
4. return a result object which contains:


    result =
      result : true
      context: message:'Hello there, Bob'
      chain  : # ... the chain used to run it

Now, let's cause a fail by not providing a message property. We'll reuse the above stuff, so delete the property, then call the chain again.

    delete context.message
    result = chain.run runOptions

What it will do:

1. 'guard' will check for `message` in context and find it missing
2. it will then call `control.fail()` with a reason
3. chain returns a result object which contains:


    result =
      result : false  # fail() causes a false result
      context: {}     # the context which we provided and didn't change
      failed :        # info about the fail() call
          reason: 'missing message' # the message given to fail()
          index : 0   # the index of the chain function which called fail()
          fn    : ... # the guard function which called control.fail()
      chain  :        # the chain used to run it


## Usage: Complex

Show many advanced features:

1. add some functions via the chain builder function
2. add an array of functions from a module and then remove one of them
3. add another group of functions and then remove multiple of them with a `select()` based on "labels" in their function options
4. disable a function so it's skipped until we want it to join in
5. enable a function which was disabled by default by its provider
6. provide a function which has its own special `this` configured, without using `bind()` (for a single function call, and the avoidance of `bind()`)
7. use `control` *inside* a function to remove that function from the chain because it only wants to run once
8. `pause()` the execution at one point to show making things asynchronous. also shows using both `resume()` and `resume.callback()` styles.
9. one function which does `control.fail()` when it can't do its work
10. one function which does `control.stop()` when it believes success has been achieved
11. one function does work both when it is first called, and, after the subsequent functions in the chain have executed
12. provide a custom `context` to the run
13. show a "temporary override" of the context for the next function
14. show a "permanent override" of the context

Start by getting the module, some functions, and building the chain:

    buildChain = require 'chain-builder'
    localFunctionsArray = require './some/lib/fn/provider'
    chain = buildChain localFunctionsArray

One of those functions has an id we can use to remove it. For example:

    someFn = () -> 'I do nothing'
    someFn.options = id: 'the-one-we-dont-want'

So, we can remove it via its ID after we've added it:

    chain.add require 'some-module-with-fns'
    chain.remove 'the-one-we-dont-want'

Some function from this module is disabled by default, so, enable it:

    chain.add require 'another-module'
    chain.enable 'the.id'

Imagine the select function is:

    selectCacheFunctions = (fn, index) ->
      # if it has the array and the array has 'cache' in it
      # then we want to "select" this one, so, return true.
      fn.options?.labels?.indexOf?('cache') > -1

It's possible to store the result of `select()` and reuse it.

    selectCacheFns = chain.select require './select-cache-fns'

Use it now to remove the matching functions, and optionally give a reason for removal:

    selectCacheFns.remove 'We are using a different caching method'

Maybe we don't want this one right now while running some initial warmups. We'll enable it later when real use begins:

    chain.disable 'monitor'

Let's say we had a function written to be run on a different object so normally we would `bind()` it. Bind causes two function calls. So, instead, `chain-builder` allows you to specify what to bind it to as an option on it. Then, it's used when chain-builder calls it. so, one function call.

    notBoundFn = someObject.someFunction
    notBoundFn.options = { this: someObject };

Example of a function performing a temporary override of the context:

    tempOverride = (control) ->
      # create some object for the next one to use instead
      contextForNextFunction = {}
      # tell control to use it *only once* (second arg defaults to false)
      control.context contextForNextFunction

Example of a function removing itself via `control.remove()`:

    iRunOnce = (control) ->
      # this function wants to do something only the first time it's run.
      # then remove itself forever. maybe it does some deferred init...
      control.remove() # optionally provide a reason

Example of a function performing asynchronous operations via `control.pause()`:

    iPauseForAsync = (control, context) ->
      # pause it by getting the resume function.
      # optionally provide a reason it's paused.
      resume = control.pause 'wait for file read'

      # optionally, create a standard callback for use with readFile
      callback = resume.callback 'read file failed', 'theFileContent'

      # do something async, use our handy callback
      fs.readFile 'some/path/to/a/file.txt', 'utf8', callback

      # or, write it out yourself and call fail() or resume() directly
      fs.readFile 'some/path/to/a/file.txt', 'utf8', (err, content) ->
        if err? then control.fail 'read file failed', err
        else
          # second param, `context`, comes in handy now instead of `this`
          context.theFileContent = content

        # always resume() whether there's an error or not.
        resume()

      # or, do something scheduled like:
      setTimeout resume, 10*1000

Example of a function using `control.stop()` and `control.context()`:

    iStopSometimes = (control, context) ->
      if @theFileContent is 'we did it already'
        control.stop 'we already have what we need'
      else
        # permanently replace the `context` with a new empty one
        control.context {}, true

Example of a function doing the "pipeline/filter" style where they call the rest of the chain and then do something with the result returned back to them.

    iRetrySometimes = (control) ->
      # let the rest of the chain do its work, we'll do something on its way back
      # to provide a new context as well, use control.context(..., true) seen above.
      result = control.next()

      # now we have the result of the calls after this function.
      # if there was something we can retry, then call things again.
      if result.hasSomeRetryableProblem?
        result = control.next()
        # could loop on this,
        # could pause each time and wait for outside influence...

      # now, pass the result back, or, create an entirely new one
      return result

This will be used as the context except when it's overridden, both temporarily and permanently. It will be returned in the result unless overridden permanently. This could be a class instance and have functions on it as well.

    context = {}

The run() accepts options included the `context` we just created:

    runOptions = context: context

Or, we can affect the context object which is built by default using `Object.create(base, props)`.

    runOptions =
      base:
        # some constant
        config: 'value'
        # some helper function you want your functions to have access to
        # via this.helperFn() or context.helperFn()
        helperFn: (input) -> 'something'

Run it with our options

    result = chain.run runOptions

The result contains:

    result =
      result : true
      context: # ... the context we provided */
      chain  : # ... the chain...

Lastly, remember all the events emitted from chain allow configuring lots of listener based operations.


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

I've added an extra convenience to the `resume` function provided by `pause()`. It now has the ability to create a callback function with the standard params: `(error, result)`. It can be provided to the usual asynchronous functions as the callback and it will handle calling `control.fail()` if an error occurs or storing the result and calling `resume()`. By default, the callback's error message is "ERROR" and the default key to store the result value into the context is `result`. Override them by providing them as args to `resume.callback(errorMessage, resultKey)`.


## Use Context or This ?

You may choose to use either. It is up to your own preferred style. It is possible to customize the this via options on the function, so, in that instance the *this* will be different than the *context* so both can be used.


## Considerations

1. `chain.add()` - passing a single function, without an array, will be treated as an array with a single function
2. `chain.add()` - passing multiple function arguments (not an array) will be treated as an array of those functions
3. the array can be changed which will affect any currently running chain executions (async) when they attempt to retrieve the next function to call
4. be careful to ensure [advanced context manipulations](#advanced-contexts) don't break others' functions


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
fn3 = -> console.log 'I wont run'

chain = buildChain array:[ fn1, fn2, fn3 ]

result = chain.run context: {done:false}
# fn3 will never run.
# result is: {
#   result: true
#   stopped:{ reason:'we are done', index:1, fn:fn2 }
#   chain: # the chain
# }
```

Here's an example of using `control.fail()`:

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> this.problem = true
fn2 = (control) -> if this.problem then control.fail 'there is a problem'
fn3 = -> console.log 'I wont run'

chain = buildChain array:[ fn1, fn2, fn3 ]

context = problem:false

result = chain.run context:context
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

### Thrown Error

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


## Pipeline/Filter Style

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


## Asynchronous

Although the above examples show synchronous execution it is possible to run a chain asynchronously using the `control.pause()` function.

An example:

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> console.log this.message1

fn2 = (control, context) ->
  console.log this.message2
  resume = control.pause 'just because'  # returns a function to call to resume execution
  setTimeout resume, 1000 # schedule resume in a second
  return # return nothing

fn3 = () -> console.log this.message3

chain = buildChain array:[fn1, fn2, fn3]
result = chain.run context:
  message1: 'in fn1'
  message2: 'in fn2 and pausing'
  message3: 'resumed and in fn3'

result = # { returned when chain is paused
#   paused: { reason: 'just because', index:1, fn:fn2 }
# }

# this will be printed before the chain is resumed and fn3 is run
console.log 'back from chain.run()'

# the console will print:
#   in fn1
#   in fn2 and pausing
#   back from chain.run()
#   resumed and in fn3
```

If your code calls the `resume` function then it will receive the final result usually returned by `chain.run()`.

Using `setTimeout()` and other similar functions will make extra work to get that. So, you may specify a `done` callback to `chain.run()` to receive the final results, or the error, when a chain run completes.

Here's an example:

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> console.log this.message1

fn2 = (control, context) ->
  console.log this.message2
  resume = control.pause 'just because'  # returns a function to call to resume execution
  setTimeout resume, 1000 # schedule resume in a second
  return # return nothing

fn3 = () -> console.log this.message3

chain = buildChain array:[fn1, fn2, fn3]

# specify a done callback as part of the options object which will be run when
# the chain run is finished
context =
  message1: 'in fn1'
  message2: 'in fn2 and pausing'
  message3: 'resumed and in fn3'

result = chain.run context:context, done:(error, results) ->
  # the results object is the same as what chain.run() returns when synchronous
  console.log 'in done'

result = # { returned when chain is paused
#   paused: { reason: 'just because', index:1, fn:fn2 }
# }

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

chain.run context: shared:'object'

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
# when called, the bound function will use apply to call
# the original function with the fn1This
fn1Bound = ->
  fn1Original.apply fn1This, Array.prototype.slice.call arguments
# so, the first call specifies a *this* which will be overridden
# by the bound function.

# for fn2, it is simpler because it passes the special this to the
# first *call*. So, no second call. No need for bind().
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


## API

### API: exported builder function

Options:

1. array
2. contextBase - used in default context builder
3. buildContext - overrides context builder

## API: Chain

### API: chain.run(options:Object[, done:Function])

### API: chain.add(fn[, fn]*)

May also provide an array as an argument.

### API: chain.remove(index:number | id:string)

### API: chain.disable(index:number | id:string | function)

### API: chain.enable(index:number | id:string | function)

### API: chain.select(function)


## API: Control

### API: control.next()

### API: control.context(Object)

### API: control.pause(reason:String)

### API: control.stop(reason:String)

### API: control.fail(reason:String)

### API: control.disable()

### API: control.enable()

### API: control.remove()


### API: Events

The chain emits these events:

1. add: when functions are added to the chain
2. remove: when functions are removed from the chain
3. start: when a chain execution starts
4. pause: when `control.pause()` is called
5. resume: when the `resume` function, returned from `control.pause()`, is called
6. stop: when `control.stop()` is called
7. fail: when `control.fail()` is called
8. disable: when `control.disable()` or `chain.disable()` is called
9. enable: when `chain.enable()` is called *and* its target actually needed enabling
10. done: when the chain is done executing because all functions have been run, or, because stop/fail were called


# JavaScript Style Usage

[CoffeeScript Usage](#usage)

## JS Usage

TODO: complete all JS code examples for each CS example above.

### JS Simple

```javascript
buildChain = require('chain-builder');

function fn1() { this.message += ' there'; }; // message = 'hello there'
// context = this,  so, the below is equivalent
// function fn1(control, context) { context.message += ' there'; };
function fn2() { this.message += ', Bob'; };  // message = 'hello there, Bob'
function fn3() { console.log(this.message); };// writes full message to console

chain = buildChain();
chain.add(fn1, fn2, fn2);
// could already be in an array like:
// chain.add([fn1, fn2, fn3])

// a mutable object given to each fn in the chain
context = {message:'hello'}

result = chain.run({context: context});
// prints 'hello there, Bob' to the console
// result has information depending on what occurred, this simple one is: {
//   result:true,
//   context: { message:'hello there, Bob' }
// }
```

## MIT License
