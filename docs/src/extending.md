# Extending Grumps

Grumps can be extended in multiple ways.  Below three possibilities are discussed, namely using an existing estimator for a different data format, introducing a new *estimator*, and introducing a new *integrator*.

## Examining output at each iteration

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


## User-specified interactions

The format of Grumps is limited to specifications that are linear in parameters.  This cannot be altered.  

The standard way that data are entered moreover presumes that there are only interactions of demographics and product level variables, interactions of random coefficients and product level variables, product level regressors (where product level regressors can include a constant), a quality variable $\xi$, and an error term $\epsilon$.  This *can be changed*.  There are three ways of accomplishing this, which are described below in increasing order of complexity.

!!! tip "Try the simplest version first"
    The other versions have advantages but are more hassle.


### Simplest version

In the simplest version, one defines a callback function called *InteractionsCallback* of the form described below.  The matrix $z$ contains the consumer interactions and the matrix $x$ the products; in both cases, the second argument is the regressor indicator. The function *InteractionsCallback* should return the value of the $t$-th interaction term for consumer $i$ and product $j$.  The default value is `z[i,t] * x[j,t]`, i.e. product interactions.  So if one returned `exp( z[i,t] + x[j,t] )` if $t = 1$ then that would replace the default first interaction term.


```
    function InteractionsCallback( z, x, i, j, t, micmac, market, products ) 
        if t > 1 
            return z[ i, t ] * x[ j, t ]
        end
        return exp( z[ i, t ] + x[ j, t ] )
    end
```

The `micmac` argument indicates whether the callback is called for the interactions in the micro portion (`:micro`) or the macro portion (`:macro`) of the likelihood.  By default, Grumps creates micro interactions only at the very beginning and macro interactions only during optimization.  The `market` argument passes the name of the market and `products` a vector with product names in the order in which they are passed, albeit that the products list is only passed if `micmac = :micro`.  These are mostly useful if one wishes to incorporate some external data.  

In the example below, the list of products is stored in the `Dict` in `productlist[1]` during the `:micro` phase, which can then be used during subsequent calls.  This can be helpful to identify which product is product `j`. A downside of the simplest approach in this case is that it creates overhead, which can be avoided if one uses the bang version, described below.

```
    const productlist = [ Dict{String,Vector{String}}() ]

    function InteractionsCallback( z, x, i, j, t, micmac, market, products ) 
        if micmac == :micro 
            if !haskey( productlist[1], market )
                productlist[1][ market ] = vcat( products, "outside good" )
            end
        end
        print( "do something with product " )
        printstyled(  productlist[1][ market ][j] ; color = :yellow )
        print( " in the market called ")
        printstyled( market; color = :blue )
        print(  " using ")
        printstyled( micmac ; color = micmac == :micro ? :green : :red )
        println( " data" )
        return z[i,t] * x[j,t]
    end
```


### Bang version

With the bang version, one creates two callback methods, one for the micro interactions and one for the macro interactions.  The difference with the simple version above is that here the user fills an entire array instead of returning a single value.

Two simple examples that achieve the same thing as if the user-defined interaction callbacks were omitted are shown below.  Remember that the list of product names is only passed in the `:micro` calls, which is the first callback.

Note that in the first callback, the last element is omitted for the simple reason that there are no data on the outside good (always the last element) in `x` during the `:micro` call.

```
    function InteractionsCallback!( A, z, x, micmac, market, products )  # micro
        for i ∈ axes( A, 1 ), j ∈ 1:size( A, 2 ) - 1, t ∈ axes( A, 3 )
            A[i,j,t] = z[i,t] * x[j,t]
        end
        return nothing
    end

function InteractionsCallback!( A, z, x, θ, micmac, market, products )   # macro
    A .= zero( eltype( A ) )
    for j ∈ axes( A, 2 )
       Threads.@threads :dynamic for i ∈ axes( A, 1 ), 
        for t ∈ axes( z, 2 )
            A[i,j] += z[i,t] * x[j,t] * θ[t]
        end
    end

    return nothing
end
```

The main advantage of the bang version is that each method is only called once for each market (for each iteration), not thousands of times.  This reduces overhead when the product identities are used in the construction of interaction terms.


### Most flexible version

The most flexible version is also the hardest, so avoid this approach unless the above two approaches are inadequate.

 Pretty much all methods that Grumps uses to create data take an input parameter named `id`.  This corresponds to the `id` set in [`DataOptions()`](@ref), which is `:Grumps` by default.  This id can be set to any other symbol.  For instance, if one set `id` to `:myid` then one could add any of the methods taking an `id` in any of the Julia code files in `src/common/data` with one's own version.  For instance, the following method is defined in `micro.jl`:
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


## Adding a new estimator

### Estimator definitions

A new estimator can be added by creating a new folder in the [estimators folder](@ref).  By creating the folder, Grumps will automatically try to load an eponymous Julia file in that folder every time Grumps is run.  For instance, in `src/estimators/cler` you see a file `cler.jl`, which loads all Julia files in the folder *other than* `description.jl`. The file `description.jl` is loaded separately and automatically. 

The symbol used for the new estimator will correspond to the folder name.  For instance, if the folder name is `foo` then the new estimator symbol will be `:foo`.

The file `description.jl` should contain exactly two functions: `name` and `Description`.  It suffices to copy the `description.jl` file from another estimators folder and changing the particulars for your estimator.

For instance, the `cler` folder contains the file `description.jl` with contents
```
name( ::Val{:cler} ) = "Conformant Likelihood with Exogeneity Restrictions"


function Description( e :: Symbol, v ::Val{ :cler } )
    @ensure e == :cler "oops!"
    return EstimatorDescription( e, name( Val( :cler ) ), 
      [ "grumps", "pmle", "grumps penalized mle", "penalized likelihood", "grumps penalized maximum likelihood", "pml", "penmaxlik", "grumps pml", "cler", "full cler" ]
      )
end
```

All you need to do here is to change all the `:cler` entries to `:foo`, to change the return value of `name` to `"Foo Estimator"` and the array of strings in the return value of `Description` to a list of descriptors of your estimation method that define it clearly and set it apart from other estimators.  Make sure that none of the descriptors are used by other estimators.

In a file loaded by `foo.jl`, preferably `types.jl`, one should define some properties of the estimators. In addition, there is a type associated with your estimator. For instance, the file `types.jl` in the `cler` folder contains

```
struct GrumpsCLEREstimator <: GrumpsPenalized
    function GrumpsCLEREstimator() 
        new()
    end
end

name( ::GrumpsCLEREstimator ) = name( Val( :cler ) )

inisout( ::GrumpsCLEREstimator ) = true

Estimator( ::Val{ :cler } ) = GrumpsCLEREstimator()
```

The estimator type `GrumpsCLEREstimator` is used to allow Grumps to use the same function name with the estimator type to call different methods.  Note that `GrumpsCLEREstimator` is a subtype of `GrumpsPenalized`, which is done to allow for a single function call with different estimator type argument to select a method for all estimators that are subtypes of `GrumpsPenalized`.

For example, if one calls a function with an estimator type (and other arguments) then there is a default method that will be called unless there is a method defined for the desired supertype (e.g. `GrumpsPenalized`), which will be called unless there is a method defined for the exact estimator type (e.g. `GrumpsCLEREstimator`).

For instance, the outer objective functions are all called `ObjectiveFunctionθ!` but which one is used depends on the estimator supertype.  For `GrumpsPenalized` it is the one in `src/common/optim/objpml.jl`.  Note that you can define different objective functions depending on e.g. the `GrumpsData` type that is passed, also.

For the new estimator `:foo` the `name` and `Estimator` methods in the above file can be changed by replacing `:cler` with `:foo` and `CLER` with `Foo` everywhere, assuming that the new estimator type is `GrumpsFooEstimator`.

The final entry in `types.jl` is the line 
```inisout( ::GrumpsCLEREstimator ) = true```
What this line does is to tell Grumps that the value of the likelihood component of the objective function in the inner optimization problem is the same as that in the outer optimization problem.  This is true for most estimators, but not for e.g. the share constraint estimator.  There are a number of properties like this (type `Estimators(true)` in the REPL to see them all), whose default values are in `src/common/types/est.jl`.

Now, the `:mdle` (the Grumps estimator with exact identification in the product level moments) and `:shareconstraint` (ditto, but where the inner optimization runs maximizes only the macro likelihood) computations differ only in the contents of the `theta.jl` and `delta.jl` files.  In this case, the `theta.jl` files produce the single market outer objective function contributions and its first two derivatives and `delta.j` does ditto for the inner objective functions.

### Data types

There are several predefined `Data` types, which can be found in `src/common/types/data.jl`.  For instance, `GrumpsData` contains a vector of `GrumpsMarketData` objects (one for each market), a `GrumpsPLMData` object, and some other things.  `GrumpsPLMData` is for the penalty term.

Each `GrumpsMarketData` object contains a `GrumpsMicroData` object and a `GrumpsMacroData` object, one for the micro portion of the likelihood, and one for the macro portion of the likelihood.  These are themselves supertypes, so you can use/require whichever subtype you desire for your estimator, but if one of the existing ones suffices then use that.

### FGH types

FGH types contain the objective function and its derivatives.  These can be by market or apply to (or contain results for) a number of markets.  If `inisout` returns `true` then the inner and outer objective `FGH` objects are physically the same.


### Space types

Grumps preallocates space for choice probabilities and related objects and reuses their values where possible.  This saves computation time.  In most instances, the space types provided will suffice.


## Adding an integrator

The default integrators used by Grumps (see [`DefaultMicroIntegrator( ::Int, ::Type )`](@ref) and [`DefaultMacroIntegrator( ::Int, ::Type )`](@ref)) are limited in their functionality.  It is possible to define a new integrator. 

!!! warning "Adding integrators is untested"
    Proceed with caution, ask for help if stuck.

The way to accomplish this is to create a new folder in `src/integrators` and create a Julia file with the same name in that folder.  For instance, the folder could be called `myintegrator` and the file in that folder `myintegrator.jl`.

There are two types of integrators.  The example below will be for a micro integrator: the procedure for adding a macro integrator is similar.

Consider the definition of the `DefaultMicroIntegrator` in `src/common/types/nodesweights.jl`:
```
    struct DefaultMicroIntegrator{T<:Flt} <: MicroIntegrator{T}   
        n   :: Int
    end
```

This defines a MicroIntegrator called `DefaultMicroIntegrator` that uses a single integer-valued parameter `n` and can handle arbitrary floating point numbers (`Flt` is shorthand for `AbstractFloat`).  We need to define a constructor for that, which is defined in the same file, namely:

```
function DefaultMicroIntegrator( n :: Int, T = F64; options = nothing )
    @ensure n > 0  "n must be positive"
    DefaultMicroIntegrator{T}( n )
end
```

This is how one creates a variable of type `DefaultMicroIntegrator`.  This constructor requires `n` to be specified, takes `Float64` as the default floating point type, and does not use any further options.  The `options` argument is there in case one wants to define additional inputs to the integrator.

For every integrator, one should define two methods: `NodesWeightsGlobal` and `NodesWeightsOneMarket`.  For the `DefaultMicroIntegrator` the method `NodesWeightsGlobal` is lengthy and its contents below are omitted.  Its `NodesWeightsOneMarket` method is very short and it is displayed in its entirety.  The full method definitions can be found in `src/common/integration/micro.jl`.

```
function NodesWeightsGlobal( ms :: DefaultMicroIntegrator{T}, d :: Int,  rng :: AbstractRNG ) where {T<:Flt}
    ( lengthy content omitted )
  return GrumpsNodesWeights{T}(n, w)
end

function NodesWeightsOneMarket( ms :: DefaultMicroIntegrator{T}, d :: Int, rng :: AbstractRNG, nwgmic :: GrumpsNodesWeights{T}, S :: Int ) where {T<:Flt}
   return nwgmic
end
```

The reason that there is both a global method and a method for a single market is that for some integrators (like `DefaultMicroIntegrator`) the nodes and weights are the same for each market so only have to be generated once in `NodesWeightsGlobal` and can then simply be reused for every market.  This is why `NodesWeightsOneMarket` for `DefaultMicroIntegrator` simply returns its `nwgmic` argument: those are simply the nodes and weights generated in `NodesWeightsGlobal`.

For the `DefaultMacroIntegrator` the converse is true: `NodesWeightsGlobal` does nothing and `NodesWeightsOneMarket` does all the work.  These methods can be found in `src/common/integration/macro.jl`, where it should be noted that the prototypes for macro integrators differ from those for micro integrators.