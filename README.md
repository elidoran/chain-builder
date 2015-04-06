# chain-builder
[![Build Status](https://travis-ci.org/elidoran/chain-builder.svg?branch=master)](https://travis-ci.org/elidoran/chain-builder)
[![Dependency Status](https://gemnasium.com/elidoran/chain-builder.png)](https://gemnasium.com/elidoran/chain-builder)
[![npm version](https://badge.fury.io/js/chain-builder.svg)](http://badge.fury.io/js/chain-builder)

Builds a **synchronous** chain of command function from an array of functions.

May choose from two styles: [chain](#usage-chain) and [pipeline](#usage-pipeline)


## Install

    npm install chain-builder

## Usage: Simple
[More Usage](#usage-chain)

```coffeescript
builder = require 'chain-builder'
chain = builder.chain (ctx) -> console.log ctx.message
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

1. allow doing work **after** other members have executed
2. provide a **different** context object to later members


## Considerations

1. passing a single function, without an array, will be treated as an array with a single function
2. passing multiple function arguments (not an array) will be treated as an array of those functions
3. a provided array will be cloned (shallow) so later changes to array do not affect the chain (rebuild chain if you need to)
4. array will be validated during the build for non-function elements


## Usage: Chain

[JavaScript Usage Example](#javascript-style-usage-chain)

### Simple

```coffeescript
builder = require 'chain-builder'

fn1 = (context) -> console.log context.message

array = [ fn1 ]

chain = builder.chain array     # passing function itself also works

result = chain message:'hello'

# prints 'hello' to the console
# result is true

```

### Stopping Chain

```coffeescript
builder = require 'chain-builder'

fn1 = (context) -> if context.problem then return false
fn2 = (context) -> console.log 'I won\'t run'

array = [ fn1, fn2 ]           # passing functions as args also works

chain = builder.chain array

result = chain problem:true

# fn2 will never run.
# result = false
```

### Use Context to Pass on a Value

```coffeescript
builder = require 'chain-builder'

fn1 = (context) -> context.give = 'high 5'
fn2 = (context) -> if context.give is 'high 5' then 'cheer'

array = [ fn1, fn2 ]           # passing functions as args also works

chain = builder.chain array

result = chain problem:true

# fn2 will, uh, *cheer*
# result = true
```

### Throw Error

```coffeescript
builder = require 'chain-builder'

fn1 = (context) -> throw new Error 'my bad'

array = [ fn1 ]           # passing function as arg also works

chain = builder.chain array

result = chain()

# fn1 will throw an error
# chain will catch it, record it into: context.chainError, and return false
# result = false
# context.chainError is the thrown Error object
```


## Usage: Pipeline


# JavaScript Style Usage

[CoffeeScript Usage](#usage-chain)

## Usage: Chain

### Simple

```javascript
builder = require('chain-builder');

fn1 = function(context) { console.log(context.message); };

array = [fn1];

chain = builder.chain(array);

result = chain({ message: 'hello' });

// prints 'hello' to the console
// result is true
```

### Stopping Chain

```javascript
builder = require('chain-builder');

fn1 = function(context) { if(context.problem) return false; };
fn2 = function(context) { console.log('I won\'t run'); };

array = [ fn1, fn2 ];           // passing functions as args also works

chain = builder.chain(array);

result = chain({problem:true});

// fn2 will never run.
// result = false
```

### Use Context to Pass on a Value

```javascript
builder = require('chain-builder');

fn1 = function(context) { context.give = 'high 5'; };
fn2 = function(context) { if(context.give === 'high 5') return 'cheer'; };

array = [ fn1, fn2 ];           // passing functions as args also works

chain = builder.chain(array);

result = chain({problem:true});

// fn2 will, uh, *cheer*
// result = true
```

### Throw Error

```javascript
builder = require('chain-builder');

fn1 = function(context) { throw new Error('my bad'); };

array = [ fn1 ];           // passing function as arg also works

chain = builder.chain(array);

context = {};

result = chain(context);

// fn1 will throw an error
// chain will catch it, record it into: context.chainError, and return false
// result = false
// context.chainError is the thrown Error object
```

## MIT License
