


abstract type Options end
abstract type DataOptions <: Options end

struct GrumpsDataOptions <: DataOptions
    micromode       ::  Symbol
    macromode       ::  Symbol
    balance         ::  Symbol
    σ2              ::  F64

    function GrumpsDataOptions( mic :: Symbol, mac:: Symbol, balance :: Symbol, σ2 :: F64 = 1.0 )
        @ensure mic ∈ [ :Hog, :Ant ] "only Hog and Ant are allowed for micromode"
        @ensure mac ∈ [ :Hog, :Ant ] "only Hog and Ant are allowed for macromode"
        @ensure balance ∈ [ :micro, :macro, :none ] "only micro macro and none are allowed for balance"
        @ensure σ2 > 0  "error variance should be positive"
        new( mic, mac, :balance, σ2  )
    end
    GrumpsDataOptions(; micromode = :Hog, macromode = :Ant, balance = :micro, σ2 = 1.0 ) = new( micromode, macromode, balance, σ2 )
end


DataOptions( x...; kwargs... ) = GrumpsDataOptions( x...; kwargs... )

abstract type OptimizationOptions end


struct OptimOptions 
    f_tol           :: F64
    g_tol           :: F64
    x_tol           :: F64
    iterations      :: Int
    show_trace      :: Bool
    store_trace     :: Bool
    extended_trace  :: Bool

    function OptimOptions( f_tol :: F64, g_tol :: F64, x_tol :: F64, it :: Int, sh :: Bool, st :: Bool, ex :: Bool )
        @ensure f_tol ≥ 0.0  "f tolerance must be nonnegative"
        @ensure g_tol ≥ 0.0  "g tolerance must be nonnegative"
        @ensure x_tol ≥ 0.0  "x tolerance must be nonnegative"
        @ensure it > 0       "iterations must be positive"
        new( f_tol, g_tol, x_tol, it, sh, st, ex )
    end

end

function OptimOptions( ::Val{ :θ}; f_tol = 1.0e-8, g_tol = 1.0e-4, x_tol = 1.0e-5, iterations = 50, show_trace = true, store_trace = true, extended_trace = true )
    OptimOptions( f_tol, g_tol, x_tol, iterations, show_trace, store_trace, extended_trace  )
end

function OptimOptions( ::Val{ :δ}; f_tol = 1.0e-8, g_tol = 1.0e-8, x_tol = 1.0e-6, iterations = 25, show_trace = false, store_trace = true, extended_trace = false )
    OptimOptions( f_tol, g_tol, x_tol, iterations, show_trace, store_trace, extended_trace  )
end

"""
    OptimOptionsθ(; 
    f_tol = 1.0e-8, 
    g_tol = 1.0e-4, 
    x_tol = 1.0e-5, 
    iterations = 25, 
    show_trace = true, 
    store_trace = true, 
    extended_trace = true )

Creates and returns an *OptimOptions* optimization options variable for the outer optimization algorithm, including the function value tolerance, the
gradient tolerance, the solution tolerance, the maximum number of iterations, whether to show the trace, whether
to store the trace, and whether to keep the extended trace.  See the **Optim** package for details.  

The current version of Grumps will largely ignore the trace-related parameters.
"""
function OptimOptionsθ( ; x... ) 
    return OptimOptions( Val( :θ ); x... )
end

"""
    OptimOptionsδ( ; 
    f_tol = 1.0e-8, 
    g_tol = 1.0e-8, 
    x_tol = 1.0e-6, 
    iterations = 25, 
    show_trace = false, 
    store_trace = true, 
    extended_trace = false )

Creates and returns an *OptimOptions* optimization options variable for the inner optimization algorithm, including the function value tolerance, the
gradient tolerance, the solution tolerance, the maximum number of iterations, whether to show the trace, whether
to store the trace, and whether to keep the extended trace.  See the **Optim** package for details.  

The current version of Grumps will largely ignore the trace-related parameters.
"""
OptimOptionsδ( ; x... ) = OptimOptions( Val( :δ ); x... )


struct GrumpsThreads
    blas        :: Int
    markets     :: Int
    inner       :: Int

    function GrumpsThreads( blas :: Int, markets :: Int, inner :: Int )
        @ensure blas > 0        "blas threads count must be positive"
        @ensure markets > 0     "markets threads count must be positive"
        @ensure inner > 0       "inner threads count must be positive"
        new( blas, markets, inner )
    end
end

function GrumpsThreads(; blas = 0, markets = 0, inner = 0 )
    nth = nthreads()
    if blas ≤ 0
        blas = min( 8, nth)
    end
    if markets ≤ 0
        markets = nth
    end
    if inner ≤ 0
        inner = nth
    end
    return GrumpsThreads( blas, markets, inner )
end


inthreads( th :: GrumpsThreads ) = th.inner
mktthreads( th :: GrumpsThreads ) = th.markets
blasthreads( th :: GrumpsThreads ) = th.blas

struct GrumpsOptimizationOptions <: OptimizationOptions
    θ               :: OptimOptions
    δ               :: OptimOptions 
    gth             :: GrumpsThreads
    memsave         :: Bool
    maxrepeats      :: Int
    probtype        :: Symbol
end


function GrumpsOptimizationOptions(; θopt = OptimOptions( Val( :θ ) ), δopt = OptimOptions( Val( :δ) ), threads = GrumpsThreads(), memsave = false, maxrepeats = 4, probtype = :fast )
    @ensure probtype ∈ [ :fast, :robust ] "only fast and robust choice probabilities are allowed"
    return GrumpsOptimizationOptions( θopt, δopt, threads, memsave, maxrepeats, probtype )
end


inthreads( o :: GrumpsOptimizationOptions )     = inthreads( o.gth )
mktthreads( o :: GrumpsOptimizationOptions )    = mktthreads( o.gth )
blasthreads( o :: GrumpsOptimizationOptions )   = blasthreads( o.gth )
probtype( o :: GrumpsOptimizationOptions )      = o.probtype
memsave( o :: GrumpsOptimizationOptions )       = o.memsave

"""
    OptimizationOptions(; 
    θopt = OptimOptionsθ(), 
    δopt = OptimOptionsδ(), 
    threads = GrumpsThreads(), 
    memsave = false, 
    maxrepeats = 4, 
    probtype = :fast )

Sets the options used for numerical optimization.  *θopt* is used for the external optimization routine,
*δopt* for the internal one.  These are both of type *OptimOptions*; see the *OptimOptionsθ* and *OptimOptionsδ*
methods for elaboration.  The *memsave* variable is set to false by default; turning it on will reduce memory
consumption significantly, but will also slow down computation.  The variable *maxrepeats* may disappear in the 
future.  

Finally, there are two ways of computing choice probabilities: robust and fast, specified by passing *:robust* or
*:fast* in *probtype*. Fast choice probabilities are the default for good reason.
"""
OptimizationOptions(x...) = GrumpsOptimizationOptions(x...)

struct StandardErrorOptions
    computeθ        :: Bool
    computeδ        :: Bool
    computeβ        :: Bool
end

StandardErrorOptions() = StandardErrorOptions( true, true, true )


