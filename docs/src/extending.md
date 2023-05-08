# Extending Grumps

Grumps can be extended in multiple ways.  Below three possibilities are discussed, namely using an existing estimator for a different data format, introducing a new *estimator*, and introducing a new *integrator*.

## examining output at each iteration

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
    If one has many markets then the δ callback is called *a lot*. Be prepared for a lot of output.  The θ callback is not called nearly as often.


## using a new data format

The format of Grumps is limited to specifications that are linear in parameters.  This cannot be altered.  The way that data are entered moreover presumes that there are only interactions of demographics and product level variables, interactions of random coefficients and product level variables, product level regressors (where product level regressors can include a constant), a quality variable $\xi$, and an error term $\epsilon$.

This can be changed, however.  Pretty much all methods that Grumps uses to create data take an input parameter named `id`.  This corresponds to the `id` set in [`DataOptions()`](@ref), which is `:Grumps` by default.  This id can be set to any other symbol.  For instance, if one set `id` to `:myid` then one could add any of the methods taking an `id` in any of the Julia code files in `src/common/data` with one's own version.  For instance, the following method is defined in `micro.jl`:
```
    function CreateInteractions( id ::Any, dfc:: AbstractDataFrame, dfp:: AbstractDataFrame, v :: Variables, T = F64 )
        MustBeInDF( v.interactions[:,1], dfc, "consumer data frame" )
        MustBeInDF( v.interactions[:,2], dfp, "product data frame" )

        S = nrow( dfc )
        J = nrow( dfp ) + 1
        dθz = size( v.interactions, 1 )
        Z = zeros( T, S, J, dθz )
        for t ∈ 1:dθz, j ∈ 1:J-1, i ∈ 1:S
            Z[i,j,t] = dfc[i, v.interactions[t,1] ] * dfp[j, v.interactions[t,2] ]
        end
        return Z
    end
```

If one now defines a new method in one's own code with 
```
    function Grumps.CreateInteractions( ::Val{ :myid }, dfc, dfp, v, T )
        ...
        ...
        ...
    return Z
end
```
then Grumps will call the newly minted method instead of the default one.  But note that one would also need to adjust the corresponding macro integration part for estimators that use both micro and macro likelihoods.  For any functions for which no user-defined methods corresponding to the given `id` are defined, the default method is called.

!!! note "hogs and ants"
    By default, Grumps saves on storage by storing *macro* draws and regressors separately (:Ant mode for macro).  If one wanted a regressor that could not be expressed as e.g. the product of a demographic variable and a product variable, then the functions `FillAθ!` and `FillZXθ!` in `src/common/probs/index.jl` may need to have new methods added, also, if one wants to continue using :Ant mode.  An alternative for small problems is to switch to :Hog mode for the macro likelihood (the micro likelihood uses :Hog mode by default).

!!! warning "two ids"
    There is one id for data creation passed in [`DataOptions()`](@ref) and one id for the optimization process passed in [`OptimizationOptions()`](@ref).  These ids *can* be different, but in most instances it is better to set these to the same value.  Note that the id used in `FillAθ!` and `FillZXθ!` is the optimization process id, not the data storage id.


## adding a new estimator

### estimator definitions

A new estimator can be added by creating a new folder in the [estimators folder](@ref).  By creating the folder, Grumps will automatically try to load an eponymous Julia file in that folder every time Grumps is run.  For instance, in `src/estimators/pml` you see a file `pml.jl`, which loads all Julia files in the folder *other than* `description.jl`. The file `description.jl` is loaded separately and automatically. 

The symbol used for the new estimator will correspond to the folder name.  For instance, if the folder name is `foo` then the new estimator symbol will be `:foo`.

The file `description.jl` should contain exactly two functions: `name` and `Description`.  It suffices to copy the `description.jl` file from another estimators folder and changing the particulars for your estimator.

For instance, the `pml` folder contains the file `description.jl` with contents
```
name( ::Val{:pml} ) = "Grumps Penalized MLE"

function Description( e :: Symbol, v ::Val{ :pml } )
    @ensure e == :pml "oops!"
    return EstimatorDescription( e, name( Val( :pml ) ), 
      [ "grumps", "pmle", "grumps penalized mle", "penalized likelihood", "grump
s penalized maximum likelihood", "pml", "penmaxlik" ]
      )
end
```

All you need to do here is to change all the `:pml` entries to `:foo`, to change the return value of `name` to `"Foo Estimator"` and the array of strings in the return value of `Description` to a list of descriptors of your estimation method that define it clearly and set it apart from other estimators.  Make sure that none of the descriptors are used by other estimators.

In a file loaded by `foo.jl`, preferably `types.jl`, one should define some properties of the estimators. In addition, there is a type associated with your estimator. For instance, the file `types.jl` in the `pml` folder contains

```
struct GrumpsPMLEstimator <: GrumpsPenalized
    function GrumpsPMLEstimator() 
        new()
    end
end

name( ::GrumpsPMLEstimator ) = name( Val( :pml ) )

inisout( ::GrumpsPMLEstimator ) = true

Estimator( ::Val{ :pml } ) = GrumpsPMLEstimator()
```

The estimator type `GrumpsPMLEstimator` is used to allow Grumps to use the same function name with the estimator type to call different methods.  Note that `GrumpsPMLEstimator` is a subtype of `GrumpsPenalized`, which is done to allow for a single function call with different estimator type argument to select a method for all estimators that are subtypes of `GrumpsPenalized`.

For example, if one calls a function with an estimator type (and other arguments) then there is a default method that will be called unless there is a method defined for the desired supertype (e.g. `GrumpsPenalized`), which will be called unless there is a method defined for the exact estimator type (e.g. `GrumpsPMLEstimator`).

For instance, the outer objective functions are all called `ObjectiveFunctionθ!` but which one is used depends on the estimator supertype.  For `GrumpsPenalized` it is the one in `src/common/optim/objpml.jl`.  Note that you can define different objective functions depending on e.g. the `GrumpsData` type that is passed, also.

For the new estimator `:foo` the `name` and `Estimator` methods in the above file can be changed by replacing `:pml` with `:foo` and `PML` with `Foo` everywhere, assuming that the new estimator type is `GrumpsFooEstimator`.

The final entry in `types.jl` is the line 
```inisout( ::GrumpsPMLEstimator ) = true```
What this line does is to tell Grumps that the objective function value in the inner optimization problem is the same as that in the outer optimization problem.  This is true for most estimators, but not for e.g. the share constraint estimator.  There are a number of properties like this (type `Estimators(true)` in the REPL to see them all), whose default values are in `src/common/types/est.jl`.

Now, the `:vanilla` (the Grumps estimator with exact identification in the product level moments) and `:shareconstraint` (ditto, but where the inner optimization runs maximizes only the macro likelihood) computations differ only in the contents of the `theta.jl` and `delta.jl` files.  In this case, the `theta.jl` files produce the single market outer objective function contributions and its first two derivatives and `delta.j` does ditto for the inner objective functions.

### Data types

There are several predefined `Data` types, which can be found in `src/common/types/data.jl`.  For instance, `GrumpsData` contains a vector of `GrumpsMarketData` objects (one for each market), a `GrumpsPLMData` object, and some other things.  `GrumpsPLMData` is for the penalty term.

Each `GrumpsMarketData` object contains a `GrumpsMicroData` object and a `GrumpsMacroData` object, one for the micro portion of the likelihood, and one for the macro portion of the likelihood.  These are themselves supertypes, so you can use/require whichever subtype you desire for your estimator, but if one of the existing ones suffices then use that.

### FGH types

FGH types contain the objective function and its derivatives.  These can be by market or apply to (or contain results for) a number of markets.  If `inisout` returns `true` then the inner and outer objective `FGH` objects are physically the same.


### Space types

Grumps preallocates space for choice probabilities and related objects and reuses their values where possible.  This saves computation time.  In most instances, the space types provided will suffice.


## adding an integrator

**to be done**