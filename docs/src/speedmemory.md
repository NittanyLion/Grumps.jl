# Speed, memory, and accuracy

## Memory conservation


By default, Grumps loads all data and then creates space for all markets for things like choice probabilities, objective functions and their derivatives, intermediate objects, etcetera.  This saves computation time, but eats memory, especially as the number of random coefficients increases.

There are several ways of addressing memory issues.  First, it is generally a good idea to be modest in the number of random coefficients one uses.  In terms of computation it adds to memory demands.

Second, one can set `memsave` in [`OptimizationOptions()`](@ref) to `true`.  This reduces memory requirements by sharing space for choice probabilities
and related objects across a number of markets based on the number of threads.  For instance, if there are ten markets and the number of market threads in [`OptimizationOptions()`](@ref) is set to two then the space for choice probabilities is shared across five markets. The downside of doing this is that it slows down computation since some objects will need to be recomputed multiple times during estimation.   This is especially true for estimators that use the penalty term in the inside optimization, i.e. currently only the full Grumps estimator.  A secondary downside is that to implement this feature without excessive allocations, the code to achieve this is low-level.  In particular, do not call `grumps!` from different threads in the same program (different processes is fine) when using `memsave`. Note that `memsave` will have no effect if the number of market threads is no less than the number of markets. 

!!! tip "When to use `memsave`"
    Try turning `memsave` on if Grumps is paging or running out of RAM. Otherwise, leave it off.  

!!! tip "Heap size hint"
    Another option if Grumps is using a lot of memory is to start Julia with `julia -t auto --heap-size-hint=2G` or similar, which makes the garbage collection routine come on more frequently.  (Requires Julia 1.9 or higher.)


## Speed

There are several reasons that would make Grumps slow:
* Grumps can naturally take a while if the data set is large.
* With quadrature, computation time grows fast in the number of random coefficients.  
* The full CLER estimator (especially with `memsave` on) is slower than its cheap alternative.  
* Using global variables is a bad idea in any programming language and especially in Julia (bury everything inside a function). In Julia type stability can also be an issue.
* Tolerances and iteration counts (not an issue with the defaults).
* Using `robust` choice probabilities makes run times longer (the default is `fast`). 
* Make sure you are not running Julia in single thread mode.  Start Julia with `julia -t 16` if you have 16 physical cores in your computer.
* The number of threads used for various activities can be specified via [`OptimizationOptions()`](@ref).  The defaults may not be optimal, but are usually ok.
* Grumps uses OpenBLAS.  MKL can be faster, though on AMD hardware some precautions must be taken.
* Grumps does not use fast math to maximize numerical stability.  This comes at the expense of speed. 
* Using a `BigFloat` type instead of `Float64` adds precision but the performance penalty is severe.

## Accuracy

The main things one can do to improve accuracy is to experiment with the tolerances.  Other options that would slow down computation are to use `robust` choice probabilities and higher precision floating points types, but that should be an option of last resort.



