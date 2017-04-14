# chain-builder
[![Build Status](https://travis-ci.org/elidoran/chain-builder.svg?branch=master)](https://travis-ci.org/elidoran/chain-builder)
[![Dependency Status](https://gemnasium.com/elidoran/chain-builder.png)](https://gemnasium.com/elidoran/chain-builder)
[![npm version](https://badge.fury.io/js/chain-builder.svg)](http://badge.fury.io/js/chain-builder)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/chain-builder/badge.svg?branch=master)](https://coveralls.io/github/elidoran/chain-builder?branch=master)

Manage an array of functions and execute them in a series with a variety of flows.

[Pair](#usage-ordering) with [ordering](https://www.npmjs.com/package/ordering) to have advanced ordering of the array of functions.

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

    npm install chain-builder --save


# Table of Contents (JS5)

[[JS6]](http://github.com/elidoran/chain-builder/blob/master/docs/README-JS6.md)
[[CS]](http://github.com/elidoran/chain-builder/blob/master/docs/README.coffee.md)

A. Usage

  1. [Basic](#usage-basic)
  2. [Simple](#usage-simple)
  3. [Complex](#usage-complex)
  4. [Considerations](#usage-considerations)
  5. [Ordering](#usage-ordering)

B. Executing a Chain

  1. [Events](#execution-events)
  2. [Control](#execution-control)
  3. [Flow Styles](#execution-flow-styles)
  4. [Context or This?](#execution-use-context-or-this-)

C. [Examples](#examples)

  1. [Stopping Chain](#examples-stopping-chain)
  2. [Pass on a Value via Context](#examples-use-context-to-pass-on-value)
  3. [Thrown Errors](#examples-thrown-error)
  4. [Pipeline/Filter](#examples-pipelinefilter-style)
  5. [Asynchronous](#examples-asynchronous)

D. [Advanced Contexts](#advanced-contexts)

  1. [Two Contexts](#contexts-the-two-contexts)
  2. [How to specify the this context](#contexts-how-to-specify-the-this-context)
  3. [Why not use bind()?](#contexts-why-not-use-bind)
  4. [Control the Shared Context](#contexts-how-to-control-the-shared-context)

E. [API](#api)

  1. [Exported Builder Function](#api-exported-builder-function)
  2. [Chain](#api-chain)

    * [chain.run()](#api-chainrun)
    * [chain.add()](#api-chainadd)
    * [chain.remove()](#api-chainremove)
    * [chain.disable()](#api-chaindisable)
    * [chain.enable()](#api-chainenable)
    * [chain.select()](#api-chainselect)

  3. [Control](#api-control)

    * [control.next()](#api-controlnext)
    * [control.context()](#api-controlcontext)
    * [control.pause()](#api-controlpause)
    * [control.stop()](#api-controlstop)
    * [control.fail()](#api-controlfail)
    * [control.disable()](#api-controldisable)
    * [control.remove()](#api-controlremove)

F. [MIT License](#mit-license)


## Usage: Basic

Here is an extremely basic example to show the basic parts working together.

```javascript
var buildChain = require('chain-builder')
  , chain = buildChain();

// you have a function
function fn1() { console.log('simple'); }

// add it. (You can supply it to `buildChain()` as well)
chain.add(fn1);

// run the chain with default options which creates an empty context
var results = chain.run();

// the results object is:
results = {
  result: true    // means it was a success. no error. no fail().
  , context: {}   // the default context is an empty object.
  , chain: /* the chain ... */
}
```

## Usage: Simple

The most commonly used features:

1. accessing the `context` via function param or `this`
2. reporting an error from inside a function
3. reviewing the final results

```javascript
// let's make our first function a guardian. it'll check for something and
// error if it's missing. For that, it needs the first arg, the `control`.
function guard(control) {
  // if the 'message' property is missing from the context object
  if (!this.message) {
    // return a false result with this error message
    control.fail('missing message');
  }
}

// for simpler functions there's no need to use either function params, use `this`
function fn1() {
  // the initial `message` value is provided to `chain.run()` below
  this.message += ' there';  // makes `message` = 'Hello there'
}

function fn2() {
  this.message += ', Bob';   // makes message = 'Hello there, Bob'
}

function fn3() {
  // writes full message to console
  console.log(this.message);
}

var chain = buildChain(fn1, fn2, fn3);
// OR: add them after a chain is created
chain.add(fn1, fn2, fn3);
// OR: add them as an array
chain.add([ fn1, fn2, fn3 ]);

    // a mutable context object given to each fn in the chain
var context = { message: 'Hello' }
    // the options provided to run() may contain a context object to use
  , runOptions = { context: context }
    // run the chain with our context
  , result = chain.run(runOptions);

// what it will do:
// 1. check the existence of the `message` property in the context
// 2. alter the context's `message` property in fn1 and fn2
// 3. print 'hello there, Bob' in function fn3
// 4. return a result object which contains:
result = {
  result: true
  , context: { message:'Hello there, Bob' }
  , chain: /* ... the chain used to run it */
}

// now let's cause a fail by not providing a message property.
// we'll reuse the above stuff, so delete the property.
delete context.message;

// and call it again
result = chain.run(runOptions);

// what it will do:
// 1. 'guard' will check for `message` in context and find it missing
// 2. it will then call `control.fail()` with a reason
// 3. chain returns a result object which contains:
result = {
  result:false  // fail() causes a false result
  , context: {} // the context which we provided and didn't change
  , failed: {   // info about the fail() call
      reason: 'missing message' // the message given to fail()
      , index: 0  // the index of the chain function which called fail()
      , fn: ...   // the guard function which called control.fail()
  }
  , chain: /* the chain used to run it */
}
```


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


```javascript
var buildChain = require('chain-builder')
  , localFunctionsArray = require('./some/lib/fn/provider')
  , chain = buildChain(localFunctionsArray);

chain.add(require('some-module-with-fns'));
// one of those functions has an id we can use to remove it:
// function someFn() {}
// someFn.options = { id: 'the-one-we-dont-want' }
chain.remove('the-one-we-dont-want');

chain.add(require('another-module'));
// some function from that module is disabled by default, so, enable it
chain.enable('the.optin.id');

// imagine the select function is:
// function selectCacheFunctions(fn, index) {
//   // if it has a 'labels' array in its function options
//   var hasArray = fn.options && fn.options.labels;
//   // if it has the array and the array has 'cache' in it
//   // then we want to "select" this one, so, return true.
//   return hasArray && (fn.options.labels.indexOf('cache') > -1);
// }
// it's possible to store the returned object and reuse its functions.
var selectCacheFns = chain.select(require('./select-cache-fns'));
// use it now to remove the matching functions,
// and optionally give a reason for removal.
selectCacheFns.remove('We are using a different caching method');

// maybe we don't want that one right now while running some initial warmups.
// we'll enable it later when real use begins.
chain.disable('monitor');

// let's say we had a function written to be run on a different object so
// normally we would `bind()` it. Bind causes two function calls. So, instead,
// `chain-builder` allows you to specify what to bind it to as an option on it.
// then, it's used when chain-builder calls it. so, one function call.
var notBoundFn = someObject.someFunction;
notBoundFn.options = { this: someObject };

function tempOverride(control) {
  // create some object for the next one to use instead
  var contextForNextFunction = {};
  // tell control to use it *only once* (second arg defaults to false)
  control.context(contextForNextFunction);
}

function iRunOnce(control) {
  // this function wants to do something only the first time it's run.
  // then remove itself forever. maybe it does some deferred init...
  control.remove(); // optionally provide a reason
}

function iPauseForAsync(control, context) {
  // pause it by getting the resume function.
  // optionally provide a reason it's paused.
  var resume = control.pause('wait for file read')

  // optionally, create a standard callback for use with readFile
    , callback = resume.callback('read file failed', 'theFileContent');

  // do something async, use our handy callback
  fs.readFile('some/path/to/a/file.txt', 'utf8', callback);

  // or, write it out yourself and call fail() or resume() directly
  fs.readFile('some/path/to/a/file.txt', 'utf8', function(err, content) {
    if (err) {
      control.fail('read file failed', err);
    } else {
      // second param, `context`, comes in handy now instead of `this`
      context.theFileContent = content;
    }

    // always resume() whether there's an error or not.
    resume();
  });

  // or, do something scheduled like:
  setTimeout(resume, 10*1000);
}

function iStopSometimes(control, context) {
  if (this.theFileContent === 'we did it already') {
    control.stop('we already have what we need');
  } else {
    // permanently replace the `context` with a new empty one
    control.context({}, true);
  }
}

function iRetrySometimes(control) {
  // let the rest of the chain do its work, we'll do something on its way back.
  // can provide a new context by passing to next() just like context()
  var result = control.next();

  // now we have the result of the calls after this function.
  // if there was something we can retry, then call things again.
  if (result.hasSomeRetryableProblem) {
    result = control.next();
    // could loop on this,
    // could pause each time and wait for outside influence...
  }
}

// this will be used as the context except when it's overridden,
// both temporarily and permanently.
// it will be returned in the result unless overridden permanently.
// this could be a class instance and have functions on it as well.
var context = {}
// the run() accepts options including the `context` we just created
  , runOptions = { context: context };

// Or, we can affect the context object which is built by default using
// Object.create(base, props);
var runOptions2 = {
  base: {
    // some constant
    config: 'value'
    // some helper function you want your functions to have access to
    // via this.helperFn() or context.helperFn()
    , helperFn: function(input) { return 'something'; }
 }
};

// run it with our options
var result = chain.run(runOptions);

// result contains:
result = {
  result   : true
  , context: /* the context we provided */
  , chain  : /* the chain... */
}

// lastly, remember all the events emitted from chain allow
// configuring lots of listener based operations.
```


## Usage: Considerations

1. `chain.add()` - passing a single function, without an array, will be treated as an array with a single function
2. `chain.add()` - passing multiple function arguments (not an array) will be treated as an array of those functions
3. the array can be changed which will affect any currently running chain executions (async) when they attempt to retrieve the next function to call
4. be careful to ensure [advanced context manipulations](#advanced-contexts) don't break others' functions


## Usage: Ordering

Use [ordering](https://www.npmjs.com/package/ordering) to order functions in the array. This allows contributing functions from multiple modules into a single chain and having them ordered based on advanced dependency constraints.

Here's an example of how to implement it with features:

1. multiple changes won't trigger ordering multiple times because it is ordered once before a `run()` starts.
2. it will only order it when it has been changed since the last time it was ordered

```javascript
// get that library
order = require('ordering');

// use a listener for both 'add' and 'remove' events
function markChanged(event) {
  // mark the chain as no longer ordered
  event.chain.__isOrdered = false;
}

// use a listener for 'start' which will order an unordered array
function ensureOrdered(event) {
  // unless it has specifically been set to true then we order it.
  // the first 'start' it may be undefined, we'll order it then.
  if (event.chain.__isOrdered !== true) {
    order(event.chain.array);
    event.chain.__isOrdered = true;
  }
}

// add listeners to any chain instance you want ordered
chain.on('add', markChanged);
chain.on('remove', markChanged);
chain.on('start', ensureOrdered);
// Note, didn't listen to 'clear' because that causes
// an empty array which *is* "ordered".
```


### Execution: Events

The chain emits these events:

1. **add** -  when functions are added to the chain
2. **remove** - when functions are removed from the chain
3. **start** - when a chain execution starts
4. **pause** - when `control.pause()` is called
5. **resume** - when the `resume` function, returned from `control.pause()`, is called
6. **stop** - when `control.stop()` is called
7. **fail** - when `control.fail()` is called
8. **disable** - when `control.disable()` or `chain.disable()` is called
9. **enable** - when `chain.enable()` is called *and* its target actually needed enabling
10. **done** - when the chain is done executing because all functions have been run, or, because stop/fail were called


## Execution: Control

By default, each function will be called in sequence and the `this` will be the `context` object. This supports a basic 'chain of command' with functions having no params using the `this` to access the context.

Each function is called with the parameters `(control, context)`. The *control* object is specific to each call to `chain.run()`. The *context* object is either an empty object by default, or, the context specified to the `chain.run()` call.

The `control` parameter replaces the usual `next` and allows changing the execution flow in multiple ways.

1. pause - pauses execution until the returned resume callback is called
2. stop - ends execution as a success
3. fail - ends execution as an error
4. context - override context for next function, or all functions, and continue chain execution
5. next - continues the chain execution and then returns so you can do something after that and before you return a result

Also, a `done` callback may be provided to the `chain.run()` call. It will be called with `(error, results)` when the chain is completed via any of the various flows.


## Execution: Flow Styles

A "chain of command" example is in the [simple example](#usage-simple). Each function is called in sequence.

A "pipeline/filter" may call `result = control.next()` to execute the later functions, then, do more work after that, and finally return the received `result` (or their own result, if desired). This allows it to do work *after* the other functions were called. Note, this assumes a synchronous execution through the entire chain afterwards. If a later function uses `control.pause()` then a result containing the paused info will be returned to `control.next()`.

Asynchronous steps are achievable using `resume = control.pause()`. Once called, the chain will wait to continue execution until the *resume* function is called. The *pause* function accepts a `reason` value which will stored in the *control*. Note, the current result will be returned back through the synchronous executions and return a final result containing the `paused` information.

Sometimes it's helpful to end a chain early because its work is complete without calling the later functions. Use `control.stop()` to do that. It will return a result back through the synchronous executions. The *stop* function accepts a `reason` value which will be part of the returned results.

It's possible to end the chain because an error has occurred with `control.fail()`. It will return a result back through the synchronous executions. The *fail* function accepts a `reason` value which will be part of the returned results.

I've added an extra convenience to the `resume` function provided by `pause()`. It now has the ability to create a callback function with the standard params: `(error, result)`. It can be provided to the usual asynchronous functions as the callback and it will handle calling `control.fail()` if an error occurs or storing the result and calling `resume()`. By default, the callback's error message is "ERROR" and the default key to store the result value into the context is `result`. Override them by providing them as args to `resume.callback(errorMessage, resultKey)`.


## Execution: Use Context or This ?

You may choose to use either. It is up to your own preferred style. It is possible to customize the this via options on the function, so, in that instance the *this* will be different than the *context* so both can be used.


### Execution: Stopping Chain

You may stop a chain's execution in two ways:

1. `control.stop()` - means a successful conclusion was reached
2. `control.fail()` - means a failure prevents the chain from continuing

Each of these stores the same information into the *control*:

1. *reason* - the reason value provided to the function call
2. *index* - the index in the array of the function which called stop/fail
3. *fn* - the function which called stop/fail

Here's an example of using `control.stop()`:

```javascript
var buildChain = require('chain-builder');

function fn1() { this.done = true; }
function fn2(control) { if(this.done) control.stop('we are done'); }
function fn3() { console.log('I wont run'); }

var chain = buildChain({array:[ fn1, fn2, fn3 ]});

var result = chain.run({ context:{done:false} });
// fn3 will never run.
result = {
  result   : true
  , stopped: { reason:'we are done', index:1, fn:fn2 }
  , chain  : // the chain
}
```

Here's an example of using `control.fail()`:

```javascript
var buildChain = require('chain-builder');

function fn1() { this.problem = true; }
function fn2(control) { if(this.problem) control.fail('there is a problem'); }
function fn3() { console.log('I wont run'); }

var chain = buildChain({ array:[ fn1, fn2, fn3 ] });

var context = { problem:false };

var result = chain.run({ context:context });
// fn3 will never run.
result = {
  result  : false
  , failed: { reason:'there is a problem', index:1, fn:fn2 }
  , chain : // the chain
};
```

### Example: Use Context to Pass on a Value

Shown many times above already, the context object is available to each function. Here is an explicit example of doing so:

```javascript
var buildChain = require('chain-builder');

function fn1() { this.give = 'high 5'; }
function fn2() { if(this.give == 'high 5') 'cheer'; }

var chain = buildChain({ array:[ fn1, fn2 ] });

var result = chain.run();  // will use an empty object as context
// fn2 will, uh, *cheer*
```

### Thrown Error

What if a function throws an error?

```javascript
buildChain = require('chain-builder');

function fn1() { throw new Error('my bad'); }

var chain = buildChain({ array:[fn1] });

var result = chain.run();

// fn1 will throw an error
// chain will catch it, end the chain, and include it in the result
result = {
  result : true
  , context: {}
  , failed: {
      reason : 'caught error'
      , index: 0
      , fn   : fn1
      , error: // the thrown error
  }
}
```


## Example: Pipeline/Filter Style

This style allows performing work after the later functions return. It relies on synchronous execution.

Here is an example:

```javascript
var buildChain = require('chain-builder');

function fn1(control) {
  // provide some value into the context from some operation
  this.value = doSomeOperation();

  // call the later functions which will do something with the value
  var result = control.next();

  // check for an error before doing more work
  if (result && !!result.error) {  
      // do something after the rest of the chain has run
      this.anotherValue = someOtherOperation(this.valueFromLaterFunctions);
  }

  // then let the function return the result it received
  // Note, this can be changed as well, or, not returned at all.
  return result;
}

function fn2() { this.valueFromLaterFunctions = someOperationOfItsOwn(); }

var chain = buildChain({ array:[fn1, fn2] })
  , result = chain.run();

// the result is:
result = {
  value: 'something'                        // <-- fn1 put this into context
  valueFromLaterFunctions: 'something more' // <-- fn2 put this into context
  anotherValue: 'something else'            // <-- fn1 did this *after* fn2 ran
}
```


## Example: Asynchronous

Although the above examples show synchronous execution it is possible to run a chain asynchronously using the `control.pause()` function.

An example:

```javascript
var buildChain = require('chain-builder');

function fn1() { console.log(this.message1); }

function fn2(control, context) {
  console.log(this.message2);
  // returns a function to call to resume execution
  var resume = control.pause('just because')
   schedule resume in a second
  setTimeout(resume, 1000);
  return
}

function fn3() { console.log(this.message3); }

var chain = buildChain({ array:[fn1, fn2, fn3] })
  , result = chain.run({
      context: {
        message1  : 'in fn1'
        , message2: 'in fn2 and pausing'
        , message3: 'resumed and in fn3'
      }
    });

// returned when chain is paused
result = {
  paused: { reason: 'just because', index:1, fn:fn2 }
}

// this will be printed before the chain is resumed and fn3 is run
console.log('back from chain.run()');

/* the console will print:
 in fn1
 in fn2 and pausing
 back from chain.run()
 resumed and in fn3
*/
```

If your code calls the `resume` function then it will receive the final result usually returned by `chain.run()`.

Using `setTimeout()` and other similar functions will make extra work to get that. So, you may specify a `done` callback to `chain.run()` to receive the final results, or the error, when a chain run completes.

Here's an example:

```javascript
var buildChain = require('chain-builder');

function fn1() { console.log(this.message1); }

function fn2(control, context) {
  console.log(this.message2);
  // returns a function to call to resume execution
  var resume = control.pause('just because');
  setTimeout(resume, 1000); // schedule resume in a second
  return
}

function fn3() { console.log(this.message3); }

var chain = buildChain({ array:[fn1, fn2, fn3] });

// specify a done callback as part of the options object which will be run when
// the chain run is finished
var context = {
  message1: 'in fn1'
  message2: 'in fn2 and pausing'
  message3: 'resumed and in fn3'
}

var result = chain.run({
  context:context
  , done: function(error, results) {
    // the results object is the same as what chain.run()
    // returns when synchronous
    console.log('in done');
  }
});

result = { // returned when chain is paused
  paused: { reason: 'just because', index:1, fn:fn2 }
}

// this will be printed before the chain is resumed and fn3 is run, and,
// before the done callback is called, of course
console.log('back from chain.run()');

/* the console will print:
 in fn1
 in fn2 and pausing
 back from chain.run()
 resumed and in fn3
 in done
*/
```


## Advanced Contexts

There are two "contexts" which have been the *same* in all the above examples.
It is possible to make them different for advanced use. Please, be careful :)

### Contexts: The two contexts

1. **shared context** : the second argument passed to each function

```javascript
function (control, context) {
  console.log('<-- that context');
}
```

2. **this context** : the *this* while each function is executing

```javascript
function(control, context) {
  console.log('that context-->', this.someProperty);
}
```

### Contexts: How to specify the `this` context

Provide an options object on the function which includes a `this` property. When you do, the `this` will be set as the *this* for the function.

```javascript
var buildChain = require('chain-builder')
  , specificThis = { some:'special this' };

function fn(control, sharedContext) {
  console.log('*this* is specificThis. some=', this.some);
  console.log('sharedContext is a shared ', sharedContext.shared);
}

fn.options = { this: specificThis };

var chain = buildChain({ array:[fn] });

chain.run({ context: shared:'object' });

/* prints:

*this* is specificThis. some=special this
sharedContext is a shared object

*/
```

### Contexts: Why not use `bind()` ?

When using `bind()` it wraps the function with another function which calls it with the `this` context specified. That means to call the function it's now two function calls.

When specifying the `this` via an option it is used in the `fn.call()` as an argument. It doesn't make more work.

See:

```javascript
// we'll use bind on this one, that's a one and a capital Oh
function fn1Original() { console.log(this.message); }
var fn1This = { message:'I am two calls' }
  , fn1Bound = fn1.bind(fn1This);

// we'll use the `options.this` on this one
function fn2() { console.log(this.message); }
var fn2This = { message:'I am one call' }
fn2.options = { this:specialThis }

var chain = buildChain();

chain.add(fn1Bound, fn2);
chain.run();

// for fn1, it is equivalent to this:
// the chain will call the bound function like this:
fn1Bound.call(context, control, context);

// when called, the bound function will use apply to call
// the original function with the fn1This
fn1Bound() {
  fn1Original.apply fn1This, Array.prototype.slice.call arguments
}
// so, the first call specifies a *this* which will be overridden
// by the bound function.

// for fn2, it is simpler because it passes the special this to the
// first *call*. So, no second call. No need for bind().
fn2.call(fn2.options.this, control, context);
```

Note, using `control.context()` overrides the *context* provided to the next function. Using `fn.options.this` overrides the *this*. This means, it's possible to completely change what a function receives as context and this and have a different view than all other functions called in a chain.

### Contexts: How to Control the Shared Context

The *shared context* can be manipulated in multiple ways.

When calling `chain.run()` you may specify a context as an option: `chain.run context:{}`. See more in the [chain.run() API](#api-chainrun).

Once a chain is running you may alter the context used both *permanently* and *impermanently* using the `chain.context()` function. That function will also execute the next function in the chain.

1. `control.context newContext` - this will override the context used by the next function called *only*. the default context is unaffected and will be used by functions after the next one. A function may choose to pass on this *impermanently* overridden context by doing an override (`control.context context`) again and passing the context to it.
2. `control.context newContext, true` - the *true* means it's a *permanent* override. It will set the default context used for all subsequent functions. Also, the default context is supplied in the final results, so, a permanently overridden context will then be in the final results.

Here is an example of an impermanent override:

```javascript
var buildChain = require('chain-builder')
  , defaultContext = {}
  , overrideContext = {};

function fn1() { this.fn1 = 'this'; }

function fn2(control, context) { context.fn2 = 'context'; }

function fn3(control) {
  this.fn3 = 'this';
  control.context(overrideContext);
}

function fn4(control, context) {
  this.fn4 = 'this';
  context.fn4 += ', context';
}

function fn5(control, context) {
  this.fn5 = 'this';
  context.fn5 += ', context';
}

var chain = buildChain({ array:[fn1, fn2, fn3, fn4, fn5] })
  , result = chain.run({ context:defaultContext });

// result is:
result = {
  result:true
  , context: { // this is the default context, missing `fn4`
    fn1  : 'this'
    , fn2: 'context'
    , fn3: 'this'
    , fn5: 'this, context'
  }
  , chain: // the chain
}

// the overrideContext is:
overrideContext = {
  fn4: 'this, context'
}
```

Only `fn4` received the `overrideContext`.

Here is an example of a permanent override:

```javascript
var buildChain = require('chain-builder')
  , defaultContext = {}
  , overrideContext = {};

function fn1() { this.fn1 = 'this'; }

function fn2(_, context) { context.fn2 = 'context'; }

function fn3(control) {
  this.fn3 = 'this';
  control.context(overrideContext, true) // <-- the `true` makes it permanent
}

function fn4(control, context) {
  this.fn4 = 'this';
  context.fn4 += ', context';
}

function fn5(control, context) {
  this.fn5 = 'this';
  context.fn5 += ', context';
}

var chain = buildChain({ array:[fn1, fn2, fn3, fn4, fn5] })
  , result = chain.run({ context:defaultContext });

// result contains:
result = {
  result:true
  , context: {  // <-- this is the overrideContext
    fn4 : 'this, context'
    , fn5 : 'this, context'
  }
}

// wasn't returned in final result, doesn't have fn4/fn5
// defaultContext contains:
defaultContext = {
  fn1  : 'this'
  , fn2: 'context'
  , fn3: 'this'
}

// was in final result, contains fn's after the override
// overrideContext contains:
overrideContext = {
  fn4  : 'this, context'
  , fn5: 'this, context'
}
```


## API

### API: Exported Builder Function

The module exports a single "builder" function. It accepts one parameter which can be various types. It returns a new `Chain` instance.

#### Parameter can be:

* **function** - a single function to put into the chain
* **array** - an array containing functions to put into the chain. The array contents are validated immediately and an object with an 'error' property is returned if the array contains anything other than functions.
* **object** - an object containing any of the below "options"

#### Options:

* **array** - the "array" described above as a parameter.
* **base** - used in the default context builder as the first param to `Object.create()`
* **props** - used in the default context builder as the second param to `Object.create()`
* **buildContext** - overrides the context builder. It is described below with an example.

#### Use the base or props options

The `base` and `props` are used in `Object.create(base, props)` to build the default context object. You may provide functions, or anything you could specify in an object's `prototype`. This allows adding helper functions and constants to the `context` object.

#### Example:

```javascript
function worker(control, context) {
  context.num = context.sum(context.num, 456);
}

var base = {
    num: 123
    , sum: function(a, b) { return a + b; }
  }
  , runOptions = { base: base }
  , result = chain.run(runOptions);

// results ...
result = {
  result   : true
  , chain  : // the chain...
  , context: {
    num: 579  // sum of 123 and 456
    // no `sum` because that's a prototype property.
    // do `delete context.num` and then `context.num` you'd get: 123
  }
}
```

#### Override the Context Builder Function

The `buildContext` option, the "context builder", is a function accepting the "options" object provided to `chain.run()` and returning the object to use as the `context` for that execution run. If the `options` object contains a `context` property then it should return that object, but, it may alter it before doing so.

#### Example:

```javascript
var buildChain = require('chain-builder')
  , SomeClass = require('some-module');

// this is the kind of function you'd provide as `buildContext` in options.
function contextBuilder(options) {
  if (options && options.context) {
    return options.context;
  } else {
    // the options are from `chain.run(options)`
    return new SomeClass((options && options.someOptions) || {})
  }
}

function worker(control, context) {
  // the `context` is the instance of SomeClass.
  var something = context.useSomeFunction();
  context.doSomethingElse();
}

var chain = buildChain({ buildContext: contextBuilder, array:[ worker ] })
  , runOptions = { someOptions:{ example: 'value' } }
  , result = chain.run(runOptions);

// result...
result = {
  result   : true
  , chain  : // the chain
  , context: { /* the instance of SomeClass */ }
}
```

## API: Chain

### API: chain.run()

Primary function which performs a single execution of all functions in the chain.

Parameters:

1. **options** - object containing the below options
2. **done** - an optional callback function added as a listener to the 'done' event.

Options Parameter:

1. **done** - the 'done' callback function added as a listener to the 'done' event
2. **context** - the context object provided to each function
3. **base** - when the `context` option isn't specified then `chain` will build a context object using `chain._buildContext()`. That uses `Object.create(base, props)` to build the object. The `base` option will be used there. When not specified then an empty object is used.
4. **props** - As described in for `base`, when the 'context' option isn't specified the default context is built with this option as the second arg to `Object.create(base, props)`. When not specified then `undefined` is passed.

Returns an object with properties:

1. **result** - true/false depending on success
2. **context** - the final context object. It may be the default one created, the one specified in the first parameter, or one provided by a function as a "permanent override".
3. **chain** - the chain. May seem weird to provide it, but, the same "result" is provided to the "done" callback and that may be added to more than one chain.
4. **paused** / **stopped** / **failed** - when a function calls [pause()](#api-controlpause), [stop()](#api-controlstop), or [fail()](#api-controlfail) then their corresponding property contains:

  1. **reason** - the `reason` provided to the call, or, true
  2. **index** - the index of the function in the chain which called it
  3. **fn** - the function in the chain which called it

5. **failed** - as described above, and, it may have an additional property **error** with an `Error` instance caught during execution.
6. **removed** - an array of functions removed via `control.remove()` during the execution

Keep in mind, the returned object may not have the final contents when `control.pause()` is used because it receives back what's available up to the pause point.

Examples:

```javascript
var result;

// use default context, no done callback.
result = chain.run();

// override the context
result = chain.run({ context:{} });

// and provide a done callback as second arg
result = chain.run({ context:{}}, function onDone() {});

// put done callback into run options (first arg)
result = chain.run({ context:{}, done: function onDone() {
  // on done do this...
}});

// provide a `base`, prototype, for the context
result = chain.run({ base: someProtoObject });

// provide both a `base`, prototype, and a props description for the context
// see documentation for Object.create(base, props) ...
result = chain.run({ base: someProtoObject, props: somePropsDesc });

// override the context builder completely
// see examples above in the chain builder docs.
result = chain.run({ buildContext: function contextBuilder(options) {
  // get context from options, or create it here...
}});
```


### API: chain.add()

Add functions to the end of the chain's array.

Parameters:

* all parameters may be a function and they will be grouped in an array and used in the chain
* parameter may be an array. each element will be checked to ensure they are all functions otherwise an object is returned with an `error` property. they are added to the end of the chain's array.

Returns:

An object is returned with a `result` property which has a `true` value for success, and an `added` property containing an array of all functions added.

Event:

An `add` event is emitted with the same object described in the "Returns" section above.

Examples:

```javascript
// add a single function
chain.add(fn1);

// add multiple functions
chain.add(fn1, fn2, fn3);

// add using an array
chain.add([ fn1, fn2, fn3 ]);
```


### API: chain.remove()

Remove functions from the chain's array.

Parameters:

1. the first parameter may have three different types:
  * A **number** is used as an index into the array specifying which function to remove. If the index is invalid then an object is returned with an `error` property saying the index is invalid.
  * A **function** is used as the function to remove. The array is searched for the function. If it is found it is removed.
  * A **string** is used as the `id` of the function to remove. A function's `id` is in its `options` object. If a function with the id is found then it is removed.
2. the second parameter is optional and may be anything you want. It is the "reason" for doing the removal. The "reason" is included in the return results and in the object provided to the 'remove' event.

Returns:

An object with properties:

1. **result** - true for success, false when it couldn't be found to remove
2. **reason** - supplied reason, or true by default, or 'not found' when `result` is false.
3. **removed** - an array containing the functions which were removed

Event:

A `remove` event is emitted with the same object described above as the return object.

Examples:

```javascript
var result;

// remove a function via its index.
// this removes the third function.
result = chain.remove(2);

// remove a function via itself
result = chain.remove(fn1);

// remove using the function's `id`
// function must have an `options` property,
// which is an object, and it must have an `id` property of 'theid'
result = chain.remove('theid');

// provide a reason as the second arg for any of the above types:
result = chain.remove(/* any of the above */, 'some reason');

// if a removal is successful the result is:
result = {
  result   : true
  , reason : true // the reason provided, or `true` by default
  , removed: [ ]  // array containing the removed function
}

// if an invalid index is used then the result is:
result = {
  result: false
  , reason: 'Invalid index: 0' // zero would be the actual index specified
}

// if a function is specified and it isn't found, either by itself ref, or
// by its id, then the result is:
result = {
  result: false
  , reason: 'not found'
}

// if an invalid value is specified then an error is returned:
// (anything other than: number, string, and function)
result = {
  result  : false
  , reason: 'Requires a string (ID), an index, or the function'
  , which : // the thing given to the remove() call
}
```


### API: chain.clear()

Removes all functions from the chain and emits a `clear` event containing the removed functions.

If the chain is already empty then the return, and the emitted event, will have a false `result` and `reason` 'chain is empty'.

Example:

```javascript
var result = chain.clear();
result = {
  result: true
  , removed: [ /* all functions removed */ ]
  // if array was already empty then it'll have:
  , reason: 'chain empty'
}
```


### API: chain.disable()

Disable the entire chain or a specific function in the chain.

A disabled chain will not `run()`. If `run()` is called it will return an object with `result=false`, `reason` will be 'chain disabled', and `disabled` will be the reason it was disabled.

A disabled function will be skipped during an execution run.

Parameters for disabling the entire chain:

1. this optional param is the reason for disabling the chain.
2. there's no second param when disabling the entire chain.

Parameters for disabling a single function:

1. a required value used to specify which function to disable. Read about these three types above in [chain.remove()](#api-chainremove).
2. the second param is normally optional, but, because `disable()` may also apply to the chain itself, we must differentiate `chain.disable(reasonString)` from `chain.disable(functionIdString)`. So, if the first param is a number or a function then this second param is options. If the first param is a string representing the `id` of a function, then, you **must** provide this second arg. If you don't care about its value, simply specify `true`.

Returns:

An object with properties:

1. **result** - true for success, false when the function couldn't be found to disable
2. **reason** - supplied reason, or true by default, or 'not found' when `result` is false.
3. **chain** - if the chain is disabled then it is included in the result
4. **fn** - if a funciton is removed then it is included in the result

Event:

A `disable` event is emitted containing the same result object as the return object described above.

Examples:

```javascript
var result;

// disable the entire chain.
result = chain.disable();
result = {
  result: true
  , reason: true // reason defaults to `true`
  , chain: // the chain
}

// disable the entire chain with a reason
result = chain.disable('some reason');
result = {
  result: true
  , reason: 'some reason' // reason specified
  , chain: // the chain
}


// disable a specific function
// there are three different ways to specify which function to disable
var which;

// 1. specify an index of a function
which = 3;

// 2. or specify the function itself
which = someFunction;

// 3. or specify the string id of the function
which = 'theid';

result = chain.disable(which, 'some reason');

result = {
  result  : true
  , reason: 'some reason' // specified reason, or `true`
  , fn    : // the function disabled
}

// Note, the `reason` is optional when specifying the index or function.
// NOT when specifying the `id`.
chain.disable(3);         // is okay
chain.disable(someFn);    // is okay

// NOOOOOO. this would disable the entire chain with reason 'some-id'.
chain.disable('some-id');
```


### API: chain.enable()

Enable the entire chain or a specific function in the chain.

Parameters:

1. the only parameter is determines whether to enable the chain or a function, and, which function to enable. No first parameter means enable the whole chain. Otherwise, the first param can have three types. Read about these three types above in [chain.remove()](#api-chainremove).

Returns:

An object with properties:

1. **result** - true for success, false when the function couldn't be found to disable
2. **reason** - supplied reason, or true by default, or 'not found' when `result` is false.
3. **chain** - if the chain is disabled then it is included in the result
4. **fn** - if a function is removed then it is included in the result

Note, if the target is not disabled then the return result will be `false` and contain the `reason` 'chain not disabled' or 'function not disabled'.

Event:

A `enable` event is emitted containing the same result object as the return object described above.

Note, if the target is **not disabled** then no `enable` event will be emitted.

Examples:

```javascript
var result;

// enable the entire chain.
result = chain.enable();
result = {
  result: true
  , chain: // the chain
}


// enable a specific function
// there are three different ways to specify which function to enable
var which;

// 1. specify an index of a function
which = 3;

// 2. or specify the function itself
which = someFunction;

// 3. or specify the string id of the function
which = 'theid';

result = chain.enable(which);

result = {
  result  : true
  , fn    : // the function enabled
}

// if the function or chain is NOT disabled:
result = {
  result  : false
  // for enable()
  , reason: 'chain not disabled'
  // for enable(which)
  , reason: 'function is not disabled'
}
```

### API: chain.select()

Provide a function to select functions in the chain to apply a sub-operation to.

Parameters:

1. The first parameter is the only one. It must be a function which returns true for a function to include, and false for exclude.

Returns:

An object with four sub-operation functions available:

1. **remove** - same as the `chain.remove()` function described above except called with each the selected function as the first parameter and the sub-operation's parameters provided as the second, and later, parameters. The first parameter of this `remove()` is the `reason` for the removal. It is optional.
2. **disable** - same as described for `remove` except for the `chain.disable()` function.
3. **enable** - same as described for `remove` except for the `chain.enable()` function.
4. **affect** - a special sub-operation which doesn't provide the sub-operation's action function. You provide that as the first parameter of this `affect()` call.

The function provided to `select()` receives two parameters:

1. the function it must choose to include or exclude
2. the index in the chain's array where the function is

Examples:

```javascript
function selector(fn, index) {
  return (/* something you care about on the function or the index */);
  // (index == 3)
  // (fn.options && fn.options.id == 'someid')
  // (fn.options && fn.options.tags && fn.options.tags.indexOf('sometag') > -1)
}

// this `select` is reusable.
var select = chain.select(selector);

// call the sub-operation with optional args
select.remove('some reason');
select.disable('any reason');
select.enable('blah reason');

// the affect() function is special. you provide another function:
select.affect(function(fn, index) {
  // do something with to/with the function...
});
```


## API: Control

Each `chain.run()` execution creates a new `Control` instance to oversee it and provide functionality to the functions being executed.

The `control` instance is provided to each executed function as the first parameter.

It's **not required** to make use of the `control`. Each function can ignore it and the sequential execution of the chain's functions will happen.

Example:

```javascript
function (control) {
  // use `control` as you choose. or ignore it completely.
}
```

### API: control.next()

Use `next()` **only** if you want to do work both **before and after** the later functions have run through. This is the "pipeline" or "filter" pattern because it allows a function to alter what's provided to the later functions and then do something with the results after they've run. That wouldn't be possible if it was only first or only last.

Parameters:

1. **context** - optionally specify a new context object for the next function(s)
2. **permanent** - specify whether the override context is only for the next function, or, if it's permanent. If `true` then it will replace all future contexts and become part of the final result returned back to `next()`. If left out, or, `false`, then it will only be given to the next function called. Note, that function may then choose to pass on the context.

Returns:

A final results object like what [chain.run()](#api-chainrun) receives.

Examples:

```javascript
function worker(control) {
  // do some pre work

  // maybe put something into the context, or, change some values.
  this.something = 'new value'

  // call the others:
  var result = control.next();

  // do some post work
}

function overridingWorker(control) {
  // do some pre work

  // like, create a new context for the others to use
  var newContext = { override: 'context' };

  // then call the rest of the functions.
  var result = control.next(newContext, true);

  // do some post work
}

function retryWorker(control) {
  var result = control.next();

  // if there's something worth retrying, call next again
  if (result.failed && result.failed.reason == 'some retry-able reason') {
    result = control.next();
  }
}
```

### API: control.context()

Temporarily change the context given to the next function, or, permanently change the context for all subsequent functions and make it part of the final results.

Parameters:

1. **context** - optionally specify a new context object for the next function(s)
2. **permanent** - specify whether the override context is only for the next function, or, if it's permanent. If `true` then it will replace all future contexts and become part of the final `result`. If left out, or, `false`, then it will only be given to the next function called. Note, that function may then choose to pass on the context.

Returns:

Returns undefined.

Examples:

```javascript
// only the next function called will receive the tempContext.
function tempOverrider(control) {
  var tempContext = { temp: 'context' };
  control.context(tempContext);
}

// this will change the context stored in the Control permanently
function overrider(control) {
  var newContext = { replacement: 'context' };
  control.context(newContext);
}
```


### API: control.pause()

Asynchronous execution is possible using `control.pause()` to retrieve a `resume()` function. The chain will wait until that function is called to begin executing again.

There is an additional helper function on the returned `resume` function named `callback`. Use that to create a resume callback which accepts the standard parameters `(error, result)` and handles calling `control.fail()` with an error message and the error, or, setting the `result` into the context for you.

Parameters:

1. **reason** - optionally specify a reason for pausing so it's available.

Returns:

A function which, when called (no params), will resume execution of the chain. Has a `callback` property which is another function to create an `(error, result)` style callback function which handles those for you.

Callback helper Parameters:

1. optional error message which will be passed to `control.fail()` if an error occurs. Defaults to "ERROR".
2. optional property name (result key) to set the result into the `context` with. Defaults to "result".

Event:

Emits a 'pause' event with the `paused` object as described below.

Examples:

A simple use of the resume function:

```javascript
function simpleResume(control) {
  var resume = control.pause('wait for a bit');
  // resume in a little bit...
  setTimeout(resume, 1234);
}
```

Using `resume()` within a callback:

```javascript
function worker(control, context) {
  var resume = control.pause('because i said so');

  fs.readFile('./some/file.ext', 'utf8', function callback(error, content) {
    if (error) {
      control.fail('Failed to read config file', error);
    } else {
      context.fileContent = content;
    }

    // always call resume()
    resume();
  });
}
```

Using the `resume.callback()` for the same results:

```javascript
function worker(control) {
  var resume = control.pause('because i said so')
    , callback = resume.callback('Failed to read config file', 'fileContent');

  fs.readFile('./some/file.ext', 'utf8', callback);
}

// let's look at what an error would look like as well as success
function onDone(error, result) {
  if (error) {
    // the `error` will be the `failed` object like:
    error = {
      reason : 'Failed to read config file' // message given to resume.callback
      , index: 0      // worker was first in the array
      , fun  : worker // the worker function
    }

    // the `result` will always exist, error or not.
    // if there was an error, the result is:
    result = {
      result : false
      , chain: // the chain
      , context: {} // the context (which we didn't do anything to)
      , failed: { /* this is the error object described above */ }
    }

  } else {
    // if there was no error then the result is:
    result = {
      result   : true
      , chain  : // the chain
      , context: {}
    }
  }
}

// leave out other common stuff for brevity... imagine we setup a chain
var result = chain.run({}, onDone);

// when pause() was called it returns that info to the `result` here.
result = {
  paused: {
    reason : 'because i said so' // reason provided to pause()
    , index: 0                   // worker function was first in array
    , fn   : worker              // our worker function
  }
};
```


### API: control.stop()

Stops executing the chain and returns a **success** result with the reason provided to `stop()`.

Note, this is for **early termination** of an execution. Not for an error. When there's an error use [control.fail()](#api-controlfail).


Parameters:

1. **reason** - optionally specify a reason for stopping so it's in the results.

Returns:

`true`. Yup, that's it. :)

Event:

Emits a 'stop' event with an object containing both the current `context` and the `stopped` object as described below.

Example:

```javascript
function stopper(control) {
  if (this.somethingMeaningWeAreDone) {
    return control.stop('we have what we need');
  }
}

// the final result:
result = {
  result   : true  // true because a stop() is still a success
  , chain  : // the chain
  , stopped: { // when stop() is called this object is in results
    reason : 'we have what we need' // message supplied to stop()
    , index: 0       // the index of the stopper function in the chain
    , fn   : stopper // the function which called stop()
  }
};
```


### API: control.fail()

Stops executing the chain and returns a **failure** result with the reason provided to `fail()`.

Note, this is for an error during execution. If you want to simply stop execution then use [control.stop()](#api-controlstop).

Parameters:

1. **reason** - optionally specify a reason for failing so it's in the results.

Returns:

`false`. Yup, that's it. :)

Event:

Emits a 'fail' event with an object containing both the current `context` and the `failed` object as described below.

Example:

```javascript
function failer(control) {
  if (this.somethingBad) {
    return control.fail('the sky is falling!');
  }
}

// the final result:
result = {
  result: false
  , chain: // the chain
  , failed: { // when fail() is called this object is in results
    reason : 'the sky is falling!' // message supplied to stop()
    , index: 0      // the index of the stopper function in the chain
    , fn   : failer // the function which called fail()
  }
};
```


### API: control.disable()

Disables the currently executing function. It will be skipped during execution runs until it is enabled.

This allows functions to disable themselves without resorting to calling `chain.disable()` with its necessary params.

Parameters:

1. **reason** - optionally specify a reason for disabling. Defaults to `true`.

Returns:

The same object as described above in [chain.disable()](#api-chaindisable).

Event:

Emits a 'disable' event just like [chain.disable()](#api-chaindisable).

Examples:

```javascript
function disabler(control) {
  return control.disable('I\'ve had enough for now.');
}
```


### API: control.remove()

Removes the currently executing function.

This allows functions to remove themselves without resorting to calling `chain.remove()` with its necessary params.

When a function is removed this way its removal is recorded by the Control and it will be in the final results.

Parameters:

1. **reason** - optionally specify a reason for removing the function. Defaults to `true`.

Returns:

`true`, Yup, that's it.

Event:

Emits a 'remove' event just like [chain.remove()](#api-chainremove).

Examples:

```javascript
function quitter(control) {
  return control.remove('I quit.');
}

// the final result will contain functions which removed during the
// execution run:
result = {
  result  : true // assuming it's a successful run
  , chain :      // the chain
  , context: {}  // the final context..
  , removed: [
    quitter // the function which removed itself via control.remove()
  ]
};
```


## [MIT License](LICENSE)
