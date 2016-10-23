
0.9.0 - 2016/10/23

1. added clear()
2. splicing new functions into array instead of pushing one at a time
3. including `chain` in start/done event emits

0.8.0 - 2016/10/16

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

0.7.1 - 2015/11/12

1. added emitting add/remove events

0.7.0 - 2015/11/11

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
