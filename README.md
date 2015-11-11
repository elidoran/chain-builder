# chain-builder
[![Build Status](https://travis-ci.org/elidoran/chain-builder.svg?branch=master)](https://travis-ci.org/elidoran/chain-builder)
[![Dependency Status](https://gemnasium.com/elidoran/chain-builder.png)](https://gemnasium.com/elidoran/chain-builder)
[![npm version](https://badge.fury.io/js/chain-builder.svg)](http://badge.fury.io/js/chain-builder)

Manage an array of functions and execute them in a series with a variety of flows.

Some of the features:

1. "chain of command" - call functions in series
2. "waterfall" - uses a `context` object which is provided to each function in sequence. accepts one for the initial call (unlike `async.waterfall()`). It's different than providing the output to the next function a input, however, it can achieve the same results, and, it's possible to provide an entirely new object to each subsequent function.
3. "pipeline/filter" - a series of functions which call the next one, can override the input, can do work after the later functions return
4. accepts a `done` callback to send error or result to
5. can *pause* the chain and use a callback to *resume* it; which supports asynchronous execution
6. can *stop* the chain early as a success; accepts a `reason`
7. can *fail* the chain execution as an error; accepts a `reason`
8. the context provided to each function is also the *this*, unless overridden via an option
9. the *this* can be overridden per function via an options object on the function
10. can override the context used by the next function (which can choose to pass that one on, or, allow the default context to be restored), and, can override the default context used by all future functions and returns in the result.
11. is an *EventEmitter* with events for: start, pause, resume, stop, fail, done.

## Install

    npm install chain-builder --save


## Usage: Simple
[More Usage](#usage-chain)

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

By default, each function will be called in sequence with the parameters `(control, context)`, and the `this` will be the `context` object.

This supports a basic 'chain of command' with functions having no params using the `this` to access the context.

The `control` parameter allows changing the execution flow.

1. `control.pause()` - returns a `resume` function allowing an asynchronous execution. The chain won't continue until resume is called.
2. `control.context(context:Object[, permanent:Boolean])` - overrides the context used for the next function call. If `permanent` is true, then the specified `context` object becomes the new default context and is provided as a result of the chain's execution, replacing the original context, permanently.
3. `control.stop(reason)` - stops executing functions and completes as a successful chain run. The stopped info will be included in the results.
4. `control.fail(reason)` -


## Chain or Pipeline ?

### Define: Chain

Function series which are executed in sequence and each given the same context object.

A function may stop the chain by returning false.

A function is **not** required to call a `next` function to advance the chain's execution. Unless it returns false the chain will continue after it returns.

### Define: Pipeline

Function series where only the first function is executed. It is then that function's responsibility to call the next function using a `next` provided by its caller.

Also, it must provide the context object for the next function. It may provide the same context it received, **or**, it may provide a completely different object.

As the caller of `next` it can then do more work *after* the remaining functions have executed.


### Which to use?

Use `chain` because it's nicer to avoid requiring dev's to call the next all the time.

Use `pipeline` if it's important to:

1. allow doing work **after** later members have executed
2. provide a **different** context object to later members


## Considerations

1. passing a single function, without an array, will be treated as an array with a single function
2. passing multiple function arguments (not an array) will be treated as an array of those functions
3. the array can be changed which will affect any currently running chain executions (async)
4. be careful to ensure [advanced context manipulations](#advanced-contexts) don't break others' functions

## Usage: Chain

[JavaScript Usage Example](#javascript-style-usage)

### Simple

```coffeescript
buildChain = require 'chain-builder'

fn1 = (context) -> console.log context.message
# context = this  # so, the below is equivalent
#fn1 = -> console.log this.message

chain = buildChain()
array = [ fn1 ]
chain.add array     # passing function itself also works

result = chain message:'hello'
# prints 'hello' to the console
# result is {result:true, context:{message:'hello'}}
```

### Stopping Chain

You may stop a chain's execution in two ways:

1. `control.stop()` - means a successful conclusion was reached
2. `control.fail()` - means a failure prevents the chain from continuing

Here's an example of using `control.stop()`:

```coffeescript
buildChain = require 'chain-builder'

fn1 = (control) -> if this.done then control.stop 'we are done'
fn2 = -> console.log 'I won\'t run'

array = [ fn1, fn2 ]

chain = buildChain()

result = chain.run problem:true
# fn2 will never run.
# result is: {
#   result: true
#   stopped:{ reason:'we are done', index:0, fn:fn1}
# }
```

Here's an example of using `control.fail()`:

```coffeescript
buildChain = require 'chain-builder'

fn1 = (control) -> if this.problem then control.fail 'there is a problem'
fn2 = -> console.log 'I won\'t run'

array = [ fn1, fn2 ]

chain = buildChain()

result = chain.run problem:true
# fn2 will never run.
# result is: {
#   result: false
#   stopped:{ reason:'there is a problem', index:0, fn:fn1}
# }
```

### Use Context to Pass on a Value

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> this.give = 'high 5'
fn2 = -> if this.give is 'high 5' then 'cheer'

array = [ fn1, fn2 ]

chain = buildChain()    # also accepts options object with `array`
# result is {success:true, chain:Function}

result = chain.run()          # will use an empty object as context
# fn2 will, uh, *cheer*
# result is {success:true}
```

### Throw Error

```coffeescript
buildChain = require 'chain-builder'

fn1 = -> throw new Error 'my bad'

chain = buildChain fn1           # Example without array
# result is {success:true, chain:Function}

result = chain.run()

# fn1 will throw an error
# chain will catch it, end the chain, and include it in the result
# result is {error:'chain function threw error', type:'caught', Error:Error}
```

## Advanced Contexts

There are two "contexts" which have been the *same* in all the above examples.
It is possible to make them different for advanced use. Please be careful :)

### The two contexts

1. **shared context** : the argument passed to your function

```coffeescript
    (context) -> console.log '<-- that context'
```

2. **this context** : the *this* while your function is executing

```coffeescript
    (context) -> console.log 'that context-->'+this.someProperty
```

### How to specify the `this` context

You may provide an options object on your function which includes a
`this` property. When you do, *that* `this` will be set as the *this* for
your function.

```coffeescript
buildChain = require 'chain-builder'

specificThis = some:'special this'

fn = (sharedContext) ->
  console.log '*this* is specificThis. some=', this.some
  console.log 'sharedContext is a shared ', sharedContext.shared

fn.options = this:specificThis

chain = buildChain fn
# result is {success:true, chain:Function}

result.chain shared:'object'

# prints:
#   *this* is specificThis. some=special this
#   sharedContext is a shared object
```

### Why not use `bind()` ?

When using `bind()` it wraps the function with another function which calls it with the `this` context specified. That means to call the function it's now two function calls.

When specifying the `this` via an option it is used in the `fn.call()` as an argument. It doesn't make more work.


### For a Pipeline too?

Yes. With pipelines it is more important to be mindful because we
control the *shared context* with our `next` calls.

We are often using only the *shared context*, so, calling `next context` is
the right thing to do. When using different contexts it is still the right thing
to do, so, it *should* be easy to remember to do it.

Example:

```coffeescript
buildChain = require 'chain-builder'

specificThis = some:'special this'  # make a sample object for options.this

fn = (next, sharedContext) ->
  console.log '*this* is specificThis. some=', this.some
  console.log 'sharedContext is a shared ', sharedContext.shared
  next sharedContext # not *this*

fn.options = this:specificThis   # set it in the function's options object

result = builder.pipeline fn
# result is {success:true, pipeline:Function}

result.pipeline shared:'object'  # provided the *shared context*

# prints:
#   *this* is specificThis. some=special this
#   sharedContext is a shared object
```

That is, unless you *want* to override the shared context with something else.
You still can.

Also, keep in mind the function executed next may have its own `options.this`
set which will be applied as `this` instead of the object you provide to your
`next` call. That will still become the *shared context* of the next call.


## Usage: Pipeline

TODO: fill in pipeline specific info.


## Usage: Asynchronous

The pipeline provides a *next* callback so it can be used for asynchronous operations.

# JavaScript Style Usage

[CoffeeScript Usage](#usage-chain)

## Usage: Chain

### Simple

```javascript
builder = require('chain-builder');

fn1 = function() { console.log(this.message); };
// context = this  so, the below is equivalent
//fn1 function() { console.log(this.message); };

array = [fn1];

chain = buildChain(array);
// result is {success:true, chain:Function}
// passing functions as args also works
// chain = buildChain(fn1, fn2);

result = chain.run({ message: 'hello' });

// prints 'hello' to the console
// result is {success:true}
```

### Stopping Chain

```javascript
builder = require('chain-builder');

fn1 = function() { if(this.problem) return false; };
fn2 = function() { console.log('I won\'t run'); };

array = [ fn1, fn2 ];

chain = buildChain(array);
// result is {success:true, chain:Function}

result = chain.run({problem:true});

// fn2 will never run.
// result is {error:'received false', type:'chaining'}
```

### Use Context to Pass on a Value

```javascript
builder = require('chain-builder');

fn1 = function() { this.give = 'high 5'; };
fn2 = function() { if(this.give === 'high 5') return 'cheer'; };

array = [ fn1, fn2 ];

chain = buildChain(array);

result = chain.run();

// fn2 will, uh, *cheer*
// result is {success:true}
```

### Throw Error

```javascript
builder = require('chain-builder');

fn1 = function() { throw new Error('my bad'); };

chain = builder.chain fn1

context = {};   // declare our own context to extract chainError later

result = chain(context);

// fn1 will throw an error
// chain will catch it, end the chain, and include it in the result
// result is {error:'chain function threw error', type:'caught', Error:Error}
```

## MIT License
