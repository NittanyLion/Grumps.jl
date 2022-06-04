# User Interface

## Data entry

The methods below are used to enter data into Grumps.

```@docs
Sources()
Variables()
```


## Optimization options

The default optimization options are sensible, in which case this section can be skipped.  But for those who want to play with tolerances and such, have at it.

```@docs
OptimizationOptions()
OptimOptionsθ()
OptimOptionsδ()
```

## Data storage options

The default data storage options are sensible, but some space can be saved by tinkering with the settings, which are **to be described below**  


## Estimator choice

Grumps can compute quite a few estimators and one can specify which estimator to use by passing the return value of a call to *Estimator* to the optimization routine.

The easiest way to call *Estimator* is by passing it a string that describes what it is that you want to do.  The following estimators are defined: **to be completed; don't use the Symbol argument call yet, because something funky's going on; may drop it altogether**

```@docs
Estimator( s :: String )
Estimator( s :: Symbol )
```

## Choice of integration method (samplers)

Grumps uses separate integration methods for the micro and macro components. The default choices are simple with small numbers of nodes and draws. For micro, it is Hermitian quadrature, for macro it's Monte Carlo draws. One gets the defaults if the choices are omitted.

The procedure is to create the samplers using a call to BothSamplers with the desired samplers as arguments and then pass this in your call to *GrumpsData*.
```@docs
BothSamplers( :: MicroSampler{T}, ::MacroSampler{T} ) where {T<:AbstractFloat}
DefaultMicroSampler( ::Int, ::Type )
DefaultMacroSampler( ::Int, ::Type )
```



## Data object creation

The data stored in spreadsheets or other objects have to be converted into a form that Grumps understands.  The call to *Data* achieves that.  
It takes as inputs the various choices made by the user and then creates an appropriate data object that is subsequently passed to the optimization call.

```@docs
Data()
```

## Algorithm call

**to be done**

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

