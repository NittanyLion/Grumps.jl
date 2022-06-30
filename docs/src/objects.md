# User Interface

The sections below describe the main calls needed to use Grumps.  For any functions that are not documented here, simply use ? in the REPL, e.g. ?Variables.

## Data entry

The methods below are used to enter data into Grumps.

```@docs
Sources()
Variables()
```


## Optimization options

The default optimization options are sensible, in which case this section can be skipped.  But for those who want to play with tolerances and such, have at it.

There is one exception, however, and that exception pertains to using less memory.  There is a separate section dedicated to that possibility, namely [Memory conservation](@ref)

```@docs
OptimizationOptions()
OptimOptionsθ()
OptimOptionsδ()
```

## Data storage options

The default data storage options are sensible, but some space can be saved by tinkering with the settings.  However, the only parameter that is worth changing is
σ2, which is the variance of ξ, the product level error term.  This is of no relevance for two-stage estimators like unpenalized mle.
```@docs
DataOptions()
```

## Estimator choice

Grumps can compute quite a few estimators and one can specify which estimator to use by passing the return value of a call to *Estimator* to the optimization routine.

The easiest way to call *Estimator* is by passing it a string that describes what it is that you want to do.  The following estimators are currently defined:
* the full Grumps estimator
* Grumps-style maximum likelihood, i.e Grumps without penalty
* ditto, but imposing share constraints
* GMM estimator that uses both micro and macro moments and uses quadrature instead of Monte Carlo draws in the micro moments.  The micro moments are `smart' in that they condition on $z_{im}$ instead of integrating it out.
* a mixed logit estimator

```@docs
Estimator( s :: String )
Estimator( s :: Symbol )
Estimators()
```

## Choice of integration method (integrators)

Grumps uses separate integration methods for the micro and macro components. The default choices are simple with small numbers of nodes and draws. For micro, it is Hermitian quadrature, for macro it's Monte Carlo draws. One gets the defaults if the choices are omitted.

The procedure is to create the integrators using a call to BothIntegrators with the desired integrators as arguments and then pass this in your call to *GrumpsData*.
```@docs
BothIntegrators( :: MicroIntegrator{T}, ::MacroIntegrator{T} ) where {T<:AbstractFloat}
DefaultMicroIntegrator( ::Int, ::Type )
DefaultMacroIntegrator( ::Int, ::Type )
```



## Data object creation

The data stored in spreadsheets or other objects have to be converted into a form that Grumps understands.  The call to *Data* achieves that.  
It takes as inputs the various choices made by the user and then creates an appropriate data object that is subsequently passed to the optimization call.

```@docs
Data()
```

## Algorithm call

Once all data structures have been put together, one can call the algorithm.  This is straightforward.
```@docs
    grumps!( ::Estimator, ::Data{T}, ::OptimizationOptions, ::Grumps.StartingVector{T}, ::StandardErrorOptions ) where {T<:Grumps.Flt}
```

## Retrieving results

As noted above, Grumps will return its results in a *GrumpsSolution* variable that can be queried as follows.  **to be expanded**

```@docs
getθ( sol :: GrumpsSolution )
getδ( sol :: GrumpsSolution )
getβ( sol :: GrumpsSolution )
getcoef( e :: GrumpsEstimate )
getstde( e :: GrumpsEstimate )
gettstat( e :: GrumpsEstimate )
getname( e :: GrumpsEstimate )
```


## Memory conservation

*stub; this section to be written*
