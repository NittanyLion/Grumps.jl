# Callbacks

On each iteration of both the inner and outer optimization steps, Grumps calls a callback function.  By default the callback for the inner optimization does nothing and the callback for the outer optimization prints a summary of progress.  Users can add to this by defining their own callback functions named `δcallback` and `θcallback` respectively.  These are called before Grumps continues with its own callback routine.  

To do this, one has to pass an `id` to [`OptimizationOptions()`](@ref) and define a callback that is specifically for this id.  The id should be a symbol, i.e. a word preceded by a colon.  For instance, one can specify `id = :myid` and define the callback
```
    function Grumps.θcallback( ::Val{ :myid }, statevec, e, d, o, oldx, repeatx, solution ) 

        println( "hi" )
        
    end
``` 
Then include `o = OptimizationOptions(; id = :myid )` (possibly with other options) in the program and pass `o` as an argument to `grumps!`.

This will print "hi" on every $θ$ iteration.  The first argument of `Grumps.θcallback` specifies which id this callback refers to (in case there is more than one), `statevec` is the state vector of the `Optim` package (see the documentation of that package for details), `oldx` is the $θ$-vector value of the previous iteration, and `repeatx` is a single element vector that indicates how often the same value of the parameter vector has been repeated.  Messing with the values of the arguments is not recommended.  The `Grumps.δcallback` function has the same syntax but lacks the `solution` argument.

If the `id` variable is set but no user callbacks are defined then Grumps will only execute the default callbacks.

!!! note "Do not overuse Grumps.δcallback"
    If one has many markets then the δ callback is called *a lot*. Be prepared for a lot of output.
