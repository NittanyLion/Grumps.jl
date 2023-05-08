# User Interface

The sections below describe the main calls needed to use Grumps.  For any functions that are not documented here, simply use ? in the REPL, e.g. ?Variables.

The way that Grumps works is that one first specifies where the data are stored, what specification to use, which estimator to use, etcetera, before calling the functions that actually perform work with these choices.  All sections below up to and including the choice of integration method specify things, data object creation and algorithm call create and compute things, and the remainder deals with the retrieval of estimation results and memory conservation.

## Data entry

The methods below are used to enter data into Grumps.  With [`Sources()`](@ref) one specifies where the data can be found and with [`Variables()`](@ref) which variables to use from those data sources.  

!!! tip "Two versions of the Variables method"
    There are two versions of the *Variables* method, where the main difference is the syntax.  Use whichever one you prefer.

```@docs
Sources()
Variables()
Variables( ::String, ::String, ::String, ::String )
```


## Optimization options

The default optimization options are sensible, in which case this section can be skipped.  But for those who want to play with tolerances and such, have at it.

There is one exception, however, and that exception pertains to using less memory.  There is a separate section dedicated to that possibility, namely [Memory conservation](@ref)

```@docs
OptimizationOptions()
OptimOptionsθ()
OptimOptionsδ()
GrumpsThreads(; blas = 0, markets = 0, inner = 0 )
```

## Data storage options

The default data storage options are sensible, but some space can be saved by tinkering with the settings.  However, the only parameter that is worth changing is
σ2, which is the variance of ξ, the product level error term.  This is of no relevance for two-stage estimators like unpenalized mle.
```@docs
DataOptions()
```

## Standard error options

**stub**

```@docs
StandardErrorOptions()
```

## Estimator choice

Grumps can compute quite a few estimators and one can specify which estimator to use by passing the return value of a call to `Estimator` to the optimization routine.

The easiest way to call `Estimator` is by passing it a string that describes what it is that you want to do.  The following estimators are currently defined:
* the full Grumps (CLER) estimator
* a less expensive alternative estimator with the same limit distribution as the CLER estimator
* Grumps-style maximum likelihood, i.e. CLER without penalty
* ditto, but imposing share constraints
* GMM estimator that uses both micro and macro moments and uses quadrature instead of Monte Carlo draws in the micro moments.  The micro moments are smart in that they condition on $z_{im}$ instead of integrating it out.
* a mixed logit estimator

For a description of these estimators, see [Estimators](@ref).

```@docs
Estimator( s :: String )
Estimator( s :: Symbol )
Estimators()
```

## Choice of integration method (integrators)

Grumps uses separate integration methods for the micro and macro components. The default choices are simple with small numbers of nodes and draws. For micro, it is Hermitian quadrature, for macro it's Monte Carlo draws. One gets the defaults if the choices are omitted.  The defaults chosen here are small in the sense that they emphasize speed / storage over accuracy.   To change the number of nodes or draws, simply call BothIntegrators with as argument(s), whichever of the two you
wish to change.  For instance, `integ = BothIntegrators( DefaultMicroIntegrator( 19 ) )` uses the default micro integrator with 19 nodes per dimension and the
default macro integrator with the default number of draws.

The procedure is to create the integrators using a call to BothIntegrators with the desired integrators as arguments and then pass this in your call to `Data`.
```@docs
BothIntegrators( :: MicroIntegrator{T}, ::MacroIntegrator{T} ) where {T<:AbstractFloat}
DefaultMicroIntegrator( ::Int, ::Type )
DefaultMacroIntegrator( ::Int, ::Type )
MSMMicroIntegrator( :: Int, ::Type )
```


!!! warning "Default macro integrator options"
    By default, the default macro integrator uses Monte Carlo integration with $R = 10,000$ draws unless otherwise specified.  If one does not specify randomization then the default macro integrator simply uses the first $R$ lines of draws for each market for demographics ($z$ draws) and combines them with $R$ draws from the distribution of the random coefficients ($\nu$ draws), both of which are then interacted with the product level regressors ($x$ variables).  If the spreadsheet does not contain enough rows corresponding to a market then the program will cycle and throw a warning.  With randomization with replacement, $R$ numbers are drawn from the draws spreadsheet regardless of the number of lines in the spreadsheet.  Without replacement, the same occurs and if the spreadsheet does not contain enough lines corresponding to the market, all lines are added and then the procedure is repeated.  In other words, there is replacement by necessity.  Again, a warning will be displayed. With randomization, the random numbers are drawn separately for each market.


## Data object creation

The data stored in spreadsheets or other objects have to be converted into a form that Grumps understands.  The call to `Data` achieves that.  
It takes as inputs the various choices made by the user and then creates an appropriate data object that is subsequently passed to the optimization call.

```@docs
Data()
```

## Algorithm call

Once all data structures have been put together, one can call the algorithm.  This is straightforward.
```@docs
    grumps!( ::Estimator, ::Data{T}, ::OptimizationOptions, ::Grumps.StartingVector{T}, ::StandardErrorOptions ) where {T<:Grumps.AbstractFloat}
```

## Retrieving results

As noted above, Grumps will return its results in a `GrumpsSolution` variable that can be queried or saved as follows.  You can also simply call one of the `print` or 
related functions on any of these objects.

Finally, you can call any of `minimum`, `iterations`, `iteration_limit_reached`, `converged`, `f_converged`, `g_converged`, `x_converged`, `f_calls`, `g_calls`, `h_calls`,
`f_trace`, `g_norm_trace`, `x_trace` on a `GrumpsSolution` or a `GrumpsConvergence` object in the same way that you would query the return value in the [Optim package](https://github.com/JuliaNLSolvers/Optim.jl/), albeit that they are not in the namespace by default so use `Grumps.converged` instead of `converged`.

```@docs
getθ( sol :: GrumpsSolution )
getδ( sol :: GrumpsSolution )
getβ( sol :: GrumpsSolution )
getcoef( e :: GrumpsEstimate )
getstde( e :: GrumpsEstimate )
gettstat( e :: GrumpsEstimate )
getname( e :: GrumpsEstimate )
getθcoef( sol :: GrumpsSolution )
getδcoef( sol :: GrumpsSolution )
getβcoef( sol :: GrumpsSolution )
Save( fn :: AbstractString, mt :: MimeText, x :: Any; kwargs... )
Save( fn :: AbstractString, x :: Any; kwargs... )
show( io :: IO, e :: GrumpsEstimate{T}, s :: String = ""; adorned = true, printstde = true, printtstat = true ) where {T<:AbstractFloat}
show( io :: IO, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; adorned = true, header = false, printstde = true, printtstat = true ) where {T<:AbstractFloat}
show( io :: IO, convergence :: Grumps.GrumpsConvergence{T}; header = false, adorned = true ) where {T<:AbstractFloat}
show( io :: IO, sol :: GrumpsSolution{T}; adorned = true, printθ = true, printβ = true, printδ = false, printconvergence = true ) where {T<:AbstractFloat}
show( io :: IO, mt :: MimeTex, sol :: GrumpsSolution; kwargs... ) 
show( io :: IO, mt :: MimeCSV, sol :: GrumpsSolution; kwargs... ) 
```

!!! tip "Saving results to LaTeX"
    To save estimation results directly to a LaTeX tabular, just use a `.tex` extension in the filename.  For instance, write `Save( "results.tex", sol )` if your solution is in the variable `sol`.


!!! tip "Saving output printed to terminal"
    To save the terminal output to html, one can use [Aha](https://github.com/theZiz/aha), the Ansi HTML Adapter, which is a small program (unrelated to Julia) that converts terminal output to html.  The way that would work on Linux and Mac (after successful installation) if one ran Grumps directly from the command line is to append `| aha > myrun.html`, e.g. `julia -t auto myprogram.jl | aha > myrun.html`.