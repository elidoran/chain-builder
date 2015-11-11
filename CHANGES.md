Unreleased

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
