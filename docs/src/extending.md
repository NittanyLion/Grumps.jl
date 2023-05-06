# Extending Grumps

Grumps can be extended in multiple ways.  Below three possibilities are discussed, namely using an existing estimator for a different data format, introducing a new *estimator*, and introducing a new *integrator*.

## using a new data format

The most general way of doing this is to fill the `GrumpsData` object with something of your own creation.  An easier way of doing this is to use the `UserEnhancement` argument in the call to [`Data()`](@ref).  

!!! danger "The user enhancement code has not been tested yet and needs work."
    Use it at your own risk.



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