# chain-builder
[![Build Status](https://travis-ci.org/elidoran/chain-builder.svg?branch=master)](https://travis-ci.org/elidoran/chain-builder)
[![Dependency Status](https://gemnasium.com/elidoran/chain-builder.png)](https://gemnasium.com/elidoran/chain-builder)
[![npm version](https://badge.fury.io/js/chain-builder.svg)](http://badge.fury.io/js/chain-builder)

Builds a **synchronous** "chain of command" function from an array of functions.

May [choose](#chain-or-pipeline-) from two styles: [chain](#usage-chain) and [pipeline](#usage-pipeline)


## Install

    npm install chain-builder

## Usage: Simple
[More Usage](#usage-chain)

```coffeescript
builder = require 'chain-builder'
chain = builder.chain -> console.log this.message
result = chain message:'hello'
# prints 'hello'
# result is true
```


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
3. a provided array will be cloned (shallow) so later changes to array do not affect the chain (rebuild chain if you need to)
4. array will be validated during the *build* for non-function elements (fail fast)
5. ensure [advanced context manipulations](#advanced-contexts) don't break others' functions

## Usage: Chain

[JavaScript Usage Example](#javascript-style-usage)

### Simple

```coffeescript
builder = require 'chain-builder'

fn1 = (context) -> console.log context.message
# context = this  so, the below is equivalent
#fn1 = -> console.log this.message

array = [ fn1 ]

chain = builder.chain array     # passing function itself also works

result = chain message:'hello'

# prints 'hello' to the console
# result is true

```

### Stopping Chain

```coffeescript
builder = require 'chain-builder'

fn1 = -> if this.problem then return false
fn2 = -> console.log 'I won\'t run'

array = [ fn1, fn2 ]

chain = builder.chain array    # passing functions as args also works

result = chain problem:true

# fn2 will never run.
# result = false
```

### Use Context to Pass on a Value

```coffeescript
builder = require 'chain-builder'

fn1 = -> this.give = 'high 5'
fn2 = -> if this.give is 'high 5' then 'cheer'

array = [ fn1, fn2 ]

chain = builder.chain array     # passing functions as args also works

result = chain()                # will use an empty object as context

# fn2 will, uh, *cheer*
# result = true
```

### Throw Error

```coffeescript
builder = require 'chain-builder'

fn1 = -> throw new Error 'my bad'

chain = builder.chain fn1           # Example without array

result = chain()

# fn1 will throw an error
# chain will catch it, record it into: context.chainError, and return false
# result = false
# context.chainError is the thrown Error object
```

## Advanced Contexts

There are two "contexts" which we have been the *same* in all the above examples.
It is possible to make them different for advanced used. Please be careful :)

### The two contexts

1. `context` : the argument passed to your function

```coffeescript
(context) -> console.log '<-- that context'
```

2. `this` : the *this* while your function is executing

```coffeescript
(context) -> console.log 'that context-->'+this.someProperty
```

I call #1 the "shared context".
I call #2 the "this context".

### How to specify the `this` context

You may provide an options object on your function which includes a
`this` property. When you do, *that* `this` will be set as the *this* for
your function.

```coffeescript
builder = require 'chain-builder'

specificThis = some:'special this'

fn = (sharedContext) ->
  console.log '*this* is specificThis. some=', this.some
  console.log 'sharedContext is a shared ', sharedContext.shared

fn.options = this:specificThis

chain = builder.chain fn

chain shared:'object'

# prints:
#   *this* is specificThis. some=special this
#   sharedContext is a shared object

```

### For a Pipeline too?

Yes. With pipelines it is more important to be mindful because we
control the *shared context* with our `next` calls.

We are often using only the *shared context*, so, calling `next context` is
the right thing to do. When using different contexts it is still the right thing
to do, so, it *should* be easy to remember to do it.

Example:

```coffeescript
builder = require 'chain-builder'

specificThis = some:'special this'

fn = (next, sharedContext) ->
  console.log '*this* is specificThis. some=', this.some
  console.log 'sharedContext is a shared ', sharedContext.shared
  next sharedContext # not *this*

fn.options = this:specificThis

chain = builder.pipeline fn

chain shared:'object'

# prints:
#   *this* is specificThis. some=special this
#   sharedContext is a shared object

```



## Usage: Pipeline


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

chain = builder.chain(array);

result = chain({ message: 'hello' });

// prints 'hello' to the console
// result is true
```

### Stopping Chain

```javascript
builder = require('chain-builder');

fn1 = function() { if(this.problem) return false; };
fn2 = function() { console.log('I won\'t run'); };

array = [ fn1, fn2 ];

chain = builder.chain(array);
// passing functions as args also works
// chain = builder.chain(fn1, fn2);

result = chain({problem:true});

// fn2 will never run.
// result = false
```

### Use Context to Pass on a Value

```javascript
builder = require('chain-builder');

fn1 = function() { this.give = 'high 5'; };
fn2 = function() { if(this.give === 'high 5') return 'cheer'; };

array = [ fn1, fn2 ];

chain = builder.chain(array);
// chain = builder.chain(fn1, fn2);  // passing functions as args also works

result = chain();

// fn2 will, uh, *cheer*
// result = true
```

### Throw Error

```javascript
builder = require('chain-builder');

fn1 = function() { throw new Error('my bad'); };

chain = builder.chain fn1

context = {};   // declare our own context to extract chainError later

result = chain(context);

// fn1 will throw an error
// chain will catch it, record it into: context.chainError, and return false
// result = false
// context.chainError is the thrown Error object
```

## MIT License
