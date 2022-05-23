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

