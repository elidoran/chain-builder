Unreleased

1. change to using a class
2. drop using `had` module
3. combine both chain and pipeline styles into one
4. accept a done callback to the execution call (`run()`)
5. change `next` to `control` which does a lot more than call `next`
    a. `context` overrides context and calls next function
    b. `pause` pauses chain and returns a `resume` function
    c. `stop` stops chain as successful
    d. `fail` stops chain as an error
6. add EventEmitter to emit various events
