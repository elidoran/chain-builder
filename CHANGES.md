### 0.13.0 - 2017/04/16

1. added testing to achieve 100% code coverage
2. added benchmarking to measure performance and compare to previous version
3. stored performance results of current implementation
4. revised implementation for better performance and clarity
5. measured improvement via benchmark, including screenshot of result
6. added both stop and fail actions to the object returned from `control.pause()`. Convenience instead of calling `fail()` or `stop()` and then `resume()`.
7. handled the initial build options better getting rid of some versions which wouldn't work properly
8. identified some functions which were doing something preventing them from being optimized by Node and fixed it
9. removed all use of `delete`
10. included properties in all object creations (and in constructors) to avoid slomo from adding a new property later.
11. performance testing shows importance of specifying **all** properties in the context ahead of time (with nulls) instead of allowing extra properties to be added later in the run.
12. fixed some inconsistencies in what was returned from a function
13. split up the large `control._execute()` function and isolated its "try-catch" block in its own function.
14. added testing to verify some functions are optimizable (needs to be applied to more)
15. removed semi-colons from README code
16. changed README for new pause actions
17. moved commas around in example code


### 0.12.1 - 2017/04/15

1. fixed [#6](https://github.com/elidoran/chain-builder/issues/6) so `select().remove()` works with multiple matches.

### 0.12.0 - 2017/04/12

1. change this file: change to header lines for each date/version info
2. update license with current year (2017)
3. update package dependencies
4. add Node 7 to testing commands
5. cleanup testing commands by moving the "testrun" into "test"
6. remove unnecessary "testold" script
7. update Travis CI with Node 7, caching `node_modules`, publishing code coverage
8. add code coverage deps, scripts, custom loader, and ignore for git and npm
9. add linting via coffeelint with a custom config
10. specify the exact `main` file
11. specify the `files` array to include for publishing


### 0.11.2 - 2016/11/05

1. added missing keywords

### 0.11.1 - 2016/11/01

1. added `chain` to remaining events (enable/disable)

### 0.11.0 - 2016/10/30

1. moved processing options to its own file and used it in both places
2. added array-flatten module dependency so options processing can accept multiple array arguments
3. allow multiple function arguments to builder
3. added accepting `props` option property to new chain
4. added using `props` option in the default context builder (should have been there before...)
5. removed an old link from README which should have been removed
6. added `chain` to emitted events so listeners can be generic and use the `chain` provided to it
7. added new section to the README showing how to use module `ordering` to order the array contents before a `run()`. (stick those in a separate module somewhere??)

The README in 0.10.0 said it was possible to provide *multiple* functions as arguments to `buildChain`. Which I hadn't implemented. So, now it's implemented along with the additional changes listed above.


### 0.10.0 - 2016/10/29

This was a large effort to add in all the remaining design features I had planned.
Also, as the test suite was completed it brought out some things to change.
And, as the README was completed it highlighted changes to make as well.
So, there are many changes going to 0.10.0.

I am planning on releasing this as version 1.0.0 once I've done some play testing in other work.

1. split `index` into three files. Put `Chain` and `Control` into two of them. Retain the builder function in `index`.
2. add validation in the Chain constructor. skip it when the builder function has already done it.
3. added `remove()` to both the `control` and `chain` objects to allow removing function. this makes it easy to add a function which will only run once, or any number of times until it believes it's done and wants to remove itself.
4. added `enable()` `disable()` functions to the `chain`, and `disable()` to the control. This allows a function to mark itself as disabled which causes the chain to skip it during execution. It is reversed by a call to enable. The `chain` versions accept an index, a function, or a function 'id' to specify which one to enable/disable/remove.
5. use an overridable `_buildContext` function to create the context for each chain execution
6. make the default `_buildContext` function use `base` option as the prototype and `props` option as the property descriptor for a call to `Object.create()`.
7. add `select()` function to `chain` which allows using a function to choose which chain functions to operate on for: `disable()`, `enable()`, `remove()`, and a generic one: `affect()`
8. added a lot more tests to check all these things
9. include functions removed during a chain execution via `control.remove()` in the final results
10. remember results of `select()` action operations (such as `disable()`) and include in returned results
11. added missing API documentation to README
12. wrote a new README with JavaScript (ES5) code
13. made separate JS5 and CS README files
14. add `resume.callback()` helper to apply the `resume` to standard callback pattern `(error, result)`
15. added tests for resume callback
16. changed `clear()` on an empty array to return a `true` success result
17. `control.remove()` now returns true
18. execution loop will call `control.fail()` when an error is caught
19. changed `control.context()` to *not* call `_execute()` itself. Instead, it simply returns and allows the execution loop to use the context, either temporary or permanent.
20. changed `control.next()` to also accept a new temporary/permanent context.
21. improved `control.next()` to be reentrant allowing a function to cause another execution from where it is in the array. This allows retry style behavior.


### 0.9.1 - 2016/10/23

1. added clear()
2. splicing new functions into array instead of pushing one at a time
3. including `chain` in start/done event emits


### 0.8.0 - 2016/10/16

1. added old revisions to README
2. added missing `context:context` in code examples in README
3. added a check to ensure array contains all functions
4. tweaked options processing a bit to accept a few more types of args which end up being an array
5. fixed the test scripts to run the individual one when local and test all on travis.
6. cleaned up scripts to be DRY
7. removed node 0.10 testing
8. removed the `index.js` file which just forwarded into the `lib/` folder.
9. updated LICENSE copyright year
10. switched test scripts to do one local script and changed Travis to separately test different node versions


### 0.7.1 - 2015/11/12

1. added emitting add/remove events

### 0.7.0 - 2015/11/11

1. change to using a class
2. allow adding and removing functions from chain
3. drop using `had` module
4. combine both chain and pipeline styles into one
5. accept a done callback to the execution call (`run()`)
6. change `next` to `control` which does a lot more than call `next`
    a. `next` calls next function, only
    b. `context` overrides context and calls next function
    c. `pause` pauses chain and returns a `resume` function
    d. `stop` stops chain as successful
    e. `fail` stops chain as an error
7. add EventEmitter to emit various events
