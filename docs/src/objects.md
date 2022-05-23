# Methods and types

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

## Estimator choice

```@docs
Estimator( s :: String )
Estimator( s :: Symbol )
```

## Data object creation

**to be done**

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

## Extending Grumps
