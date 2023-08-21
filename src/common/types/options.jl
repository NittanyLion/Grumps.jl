


abstract type Options end
abstract type DataOptions <: Options end
abstract type VarξOutput end


"""
    VarξHomoskedastic()

Creates a variable of type VarξHomoskedastic.  This is used to indicate that standard errors should be computed under the assumption of homoskedasticity.  This choice does not affect efficiency.  It also products an estimate of the matrix V(ξ) as part of the solution object, which can be used as an input into a possible second stage.
"""
struct VarξHomoskedastic <: VarξOutput
end


"""
    const VarξDefaultOutput = VarξHomoskedastic()
"""
const VarξDefaultOutput = VarξHomoskedastic()


"""
    VarξHeteroskedastic()

Creates a variable of type VarξHeteroskedastic.  This is used to indicate that standard errors should be computed under the assumption of heteroskedasticity.  This choice does not affect efficiency.  It also products an estimate of the matrix V(ξ) as part of the solution object, which can be used as an input into a possible second stage.
"""
struct VarξHeteroskedastic <: VarξOutput
end


"""
    VarξClustering( clusteron :: Symbol )

Creates a variable of type VarξClustering.  This is used to indicate that standard errors should be computed under the assumption of clustering.  This choice does not affect efficiency.  It also products an estimate of the matrix V(ξ) as part of the solution object, which can be used as an input into a possible second stage.  The argument is the variable one should cluster on, e.g. *VarξClustering( :market )* suggests that Grumps should cluster on the variable contained in the column in the products spreadsheet with column heading *market*.
"""
struct VarξClustering <: VarξOutput
    clusteron   :: Symbol
end


clusteron( c :: VarξClustering ) = c.clusteron

"""
    VarξUser()

Allows the user to specify its own standard error computation procedure.  Look at `Grumps.Template` to see how this is implemented.
"""
struct VarξUser <: VarξOutput
end


"""
    const VarξInput{T} = Union{ UniformScaling{T}, AbstractArray{T} } 

Type used to characterize the assumption under which the weight matrix for the product level moments component of the objective function should be computed.  This is irrelevant for consistency, conformance, or the convergence rate of the estimator but it can affect asymptotic efficiency.
"""
const VarξInput{T} = Union{ UniformScaling{T}, AbstractArray{T} } 
     
export VarξHomoskedastic, VarξHeteroskedastic, VarξClustering, VarξUser, VarξDefaultOutput, VarξInput


struct GrumpsDataOptions{T<:Flt} <: DataOptions
    VarξInput       ::  VarξInput{T}
    VarξOutput      ::  VarξOutput
    micromode       ::  Symbol
    macromode       ::  Symbol
    balance         ::  Symbol
    id              ::  Symbol

    function GrumpsDataOptions( varξinput :: VarξInput{T}, varξoutput = VarξDefaultOutput, mic = :Hog, mac =:Ant, balance = :micro, id = :Grumps ) where {T<:Flt}
        @ensure mic ∈ [ :Hog, :Ant ] "only Hog and Ant are allowed for micromode"
        @ensure mac ∈ [ :Hog, :Ant ] "only Hog and Ant are allowed for macromode"
        @ensure balance ∈ [ :micro, :macro, :none ] "only micro macro and none are allowed for balance"
        new{T}( varξinput, varξoutput, mic, mac, balance, id  )
    end

end

GrumpsDataOptions(; micromode = :Hog, macromode = :Ant, balance = :micro, σ2 = 1.0, id = :Grumps ) = 
    GrumpsDataOptions( σ2 * I, VarξDefaultOutput, micromode, macromode, balance, id )

"""
    DataOptions(; 
        micromode   = :Hog
        macromode   = :Ant
        balance     = :micro
        σ2          = 1.0
        id          = :Grumps
    )

Both this method and the one described below specify how Grumps should store its data and what it should store.  This one is simpler but has less flexibility.  The first three options are best set to their defaults, unless you know what it is you're doing.  The **σ2** option is the variance of ξ, i.e. the error variance in the product level moments.  The **id** option is used to extend Grumps with other data constructions.

    DataOptions(
        VarξInput   :: VarξInput{T},
        VarξOutput  :: VarξOutput = VarξDefaultOutput,
        micromode   :: Symbol = :Hog,
        macromode   :: Symbol = :Ant,
        balance     :: Symbol = :micro,
        id          :: Symbol = :Grumps   
    )

Both this method and the one described above specify how Grumps should store its data and what it should store.  This one is both more complex and more flexible.  The **micromode**, **macromode**, and **balance** arguments are best kept at their defaults, unless you know what it is you're doing.  The **id** option is used to extend Grumps with other data constructions.  **VarξInput** is the variance matrix to be used in the penalty term weight matrix construction.  This should be a J by J matrix where J is the number of products across all markets.  Acceptable types for **VarξInput** include UniformScaling{T} (e.g. 1.0 * I ) and AbstractMatrix{T} (sparse matrix is recommended to conserve space, but a dense matrix is allowed).  **VarξOutput** is used to indicate what assumptions on the variance of ξ must be produced in the solution, which can subsequently be used as an input in a second stage if desirable; options are *VarξHomoskedastic*, *VarξHeteroskedastic*, *VarξClustering*, and *VarξUser*.
"""
DataOptions( x...; kwargs... ) = GrumpsDataOptions( x...; kwargs... )



micromode( o :: GrumpsDataOptions ) = o.micromode
macromode( o :: GrumpsDataOptions ) = o.macromode
balance( o :: GrumpsDataOptions ) = o.balance
id( o :: GrumpsDataOptions ) = o.id
VarianceMatrixξ( o :: GrumpsDataOptions ) = o.VarξInput
VarξOutput( o :: GrumpsDataOptions ) = o.VarξOutput

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

function OptimOptions( ::Val{ :δ}; f_tol = 0.0, g_tol = 1.0e-8, x_tol = 0.0, iterations = 25, show_trace = false, store_trace = true, extended_trace = false )
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

"""
    GrumpsThreads(; 
        blas = 0, 
        markets = 0, 
        inner = 0 
        )

This sets the number of threads to be used subject to a number of caveats.  *blas* refers to the number of BLAS threads, *markets* to the number of threads
in loops over markets, and *inner* to the number of threads in inner loops.  A value of zero forces the automatic selection of the number of threads.

Of these, *inner* is not currently used at all, *market* is only used in *memsave* mode, and *blas* is used.  However, please note that the number of threads
used by Grumps altogether is the number of threads passed in via the command line argument (i.e. via the -t switch), where that number does not include the
number of BLAS threads set.
"""
function GrumpsThreads(; blas = 0, markets = 0, inner = 0 )
    nth = nthreads()
    if blas ≤ 0 || blas >nth
        blas = min( 32, nth)
    end
    if markets ≤ 0 || markets > nth
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
    id              :: Symbol
    progressbar     :: Bool
    loopvectorization   :: Bool
end


function GrumpsOptimizationOptions(; θopt = OptimOptions( Val( :θ ) ), δopt = OptimOptions( Val( :δ) ), threads = GrumpsThreads(), memsave = false, maxrepeats = 3, probtype = :fast, id = :Grumps, progressbar = false, loopvectorization = true )
    @ensure probtype ∈ [ :fast, :robust ] "only fast and robust choice probabilities are allowed"
    return GrumpsOptimizationOptions( θopt, δopt, threads, memsave, maxrepeats, probtype, id, progressbar, loopvectorization )
end


inthreads( o :: GrumpsOptimizationOptions )     = inthreads( o.gth )
mktthreads( o :: GrumpsOptimizationOptions )    = mktthreads( o.gth )
blasthreads( o :: GrumpsOptimizationOptions )   = blasthreads( o.gth )
probtype( o :: GrumpsOptimizationOptions )      = o.probtype
memsave( o :: GrumpsOptimizationOptions )       = o.memsave
id( o :: GrumpsOptimizationOptions )            = o.id
progressbar( o :: GrumpsOptimizationOptions )   = o.progressbar

"""
    OptimizationOptions(; 
    θopt = OptimOptionsθ(), 
    δopt = OptimOptionsδ(), 
    threads = GrumpsThreads(), 
    memsave = false, 
    maxrepeats = 4, 
    probtype = :fast,
    id = :Grumps,
    progressbar = false,
    loopvectorization = true
    )

Sets the options used for numerical optimization.  *θopt* is used for the external optimization routine,
*δopt* for the internal one.  These are both of type *OptimOptions*; see the *OptimOptionsθ* and *OptimOptionsδ*
methods for elaboration.  The *memsave* variable is set to false by default; turning it on will reduce memory
consumption significantly, but will also slow down computation.  The variable *maxrepeats* may disappear in the 
future.  

There are two ways of computing choice probabilities: robust and fast, specified by passing *:robust* or
*:fast* in *probtype*. Fast choice probabilities are the default for good reason.

The progress bar shows progress within an iteration in the form of colored circles at the top right hand corner of the screen.
The progress bar is turned off by default and should be off if Grumps is run without a terminal (e.g. in a batch script run on PBS or Slurm).
Loop vectorization is a new addition to Grumps and speeds up computation in most cases.

Finally, specifying id allows one to add callbacks, e.g. user functions that are called on each inner and 
outer iteration.  See the [Extending Grumps](@ref) portion of the documentation.
"""
OptimizationOptions(; x...) = GrumpsOptimizationOptions(; x...)

struct StandardErrorOptions
    computeθ        :: Bool
    computeδ        :: Bool
    computeβ        :: Bool

    function StandardErrorOptions( θ :: Bool, δ :: Bool, β :: Bool )
        new( θ, δ, β )
    end
end

"""
    StandardErrorOptions(; θ = true, δ = true, β = true )

Specifies which coefficients to create standard errors for.  If you are looking for what type of standard errors to produce, look at [`DataOptions()`](@ref).
"""
StandardErrorOptions(; θ = true, δ = true, β = true ) = StandardErrorOptions( θ, δ, β )



function show( io :: IO, o :: GrumpsOptimizationOptions; adorned = true )
    prstyledln( adorned, "Optimization options:"; color = :red, bold = true )
    for vr ∈ [ 
        [:θ, "outer optimization"], 
        [:δ, "inner optimization"], 
        [:gth, "threads"],
        [:probtype, "choice probabilities"],
        [:memsave, "memory saving"],
        [:maxrepeats, "maxrepeats"],
        [:id, "id" ],
        [:progressbar, "progressbar" ]
            ]
        prstyled( adorned, @sprintf( "%30s: ", vr[2] ); bold = true, color = :green );  println( getfield( o, vr[1] ) )
    end

end
    
function show( io :: IO, t :: GrumpsThreads; adorned = true )
    prstyledln( adorned, "\nThreads:"; color = :blue, bold = true )
    for vr ∈ [ :blas, :markets, :inner ]
        prstyled( adorned, @sprintf( "%30s: ", vr); bold = true );  println( getfield( t, vr ) )
    end
end


function show( io :: IO, o :: OptimOptions; adorned = true )
    prstyledln( adorned, "\nSingle level optimization options:"; color = :blue, bold = true )
    for vr ∈ [ :f_tol, :g_tol, :x_tol, :iterations, :show_trace, :store_trace, :extended_trace ]
        prstyled( adorned, @sprintf( "%30s: ", vr ); bold = true );  println( getfield( o, vr ) )
    end
end
