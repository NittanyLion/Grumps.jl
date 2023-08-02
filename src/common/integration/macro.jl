


function show( io :: IO, integ :: DefaultMacroIntegrator{T}; adorned = true ) where {T<:Flt}
    prstyled( adorned, "Default Macro Monte Carlo integrator "; color = :blue, bold = true )
    println( "  $(integ.n) draws,  randomization $(integ.randomize),  replacement $(integ.replacement), weights  $(integ.weights)  ")
end


function NodesWeightsGlobal( ms :: DefaultMacroIntegrator{T}, d :: Int,  draws :: Union{Nothing, DataFrame}, v :: Variables, rng :: AbstractRNG  ) where {T<:Flt}
   return GrumpsNodesWeights{T}( zeros( T, 0, 0 ), zeros(T, 0) )
end
 
 
 
# function NodesWeightsOneMarket( ms :: DefaultMacroIntegrator{T}, dθν :: Int, df :: Union{Nothing, AbstractDataFrame}, v :: Variables, rng :: AbstractRNG, nwgmac :: GrumpsNodesWeights{T} ) where {T<:Flt}
#     dθ = dθν + size( v.interactions, 1 ) 
#     n = randn( rng, T, ms.n, dθ )
#     if df ≠ nothing
#         MustBeInDF( v.interactions[:,1], df, "draws" )
#         @ensure ms.n ≤ nrow( df ) "Too few demographics draws.  This typically happens if the number of random draws specified for macro integration exceeds the number of demographics draws you have provided in the draws source"
#         for j ∈ axes( v.interactions, 1 )
#             n[ :, j ] = df[ 1:ms.n, v.interactions[j] ]
#         end
#     end
#     w = fill( 1.0/ms.n, ms.n )
#     return GrumpsNodesWeights{T}( n, w )
# end



# picking the first nwant numbers from the data, cycling if insufficient data are available
function whichset( rng :: AbstractRNG, nwant :: Int , nhave :: Int, ::Val{ false }, ::Any )
    @ensure nwant ≥ 0  "numbers of random numbers to be drawn must be nonnegative"
    nwant == 0  && return Int[]
    @ensure nhave > 0 "drawing from empty set"
    nwant ≤ nhave && return collect( 1:nwant )
    return vcat( collect( 1:nhave ), whichset( rng, nwant - nhave, nhave, false, false  ) )
end

# picking nwant numbers at random with replacement
function whichset( rng :: AbstractRNG, nwant :: Int , nhave :: Int, ::Val{ true }, ::Val{ true } )
    @ensure nwant ≥ 0  "numbers of random numbers to be drawn must be nonnegative"
    nwant == 0 && return Int[]
    @ensure nhave > 0 "drawing from empty set"
    return rand( 1:nhave, nwant )
end

# picking nwant numbers at random without replacement, cycling if we're short
function whichset( rng :: AbstractRNG, nwant :: Int , nhave :: Int, ::Val{ true }, ::Val{ false } )
    @ensure nwant ≥ 0  "numbers of random numbers to be drawn must be nonnegative"
    nwant == 0 && return Int[]
    @ensure nhave > 0 "drawing from empty set"
    nwant ≤ nhave && return sample( rng, collect(1:nhave), nwant )
    return vcat(  sample( rng, collect(1:nhave), nhave ), whichset( rng, nwant - nhave, nhave, true, false  ) )
end

whichset( rng :: AbstractRNG, nwant :: Int , nhave :: Int, randomize :: Bool, replace :: Bool ) = whichset( rng, nwant, nhave, Val( randomize ), Val( replace ) )


function NodesWeightsOneMarket( ms :: DefaultMacroIntegrator{T}, dθν :: Int, df :: Union{Nothing, AbstractDataFrame}, v :: Variables, rng :: AbstractRNG, nwgmac :: GrumpsNodesWeights{T} ) where {T<:Flt}
    dθ = dθν + size( v.interactions, 1 ) 
    n = randn( rng, T, ms.n, dθ )
    w = fill( 1.0, ms.n )
    if df ≠ nothing
        MustBeInDF( v.interactions[:,1], df, "draws" )
        ms.weights == :uniform || MustBeInDF( ms.weights, df, "draws" )
        nwant = ms.n;  nhave = nrow( df )
        if ms.n > nrow( df ) 
            @warn "Too few demographics draws (want $(nwant), have $(nhave)).  This typically happens if the number of random draws specified for macro integration exceeds the number of demographics draws you have provided in the draws source.  Will improvise."
        end
        ws = whichset( rng, ms.n, nrow( df ), ms.randomize, ms.replacement )
        for j ∈ axes( v.interactions, 1 )
            n[ :, j ] = df[ ws, v.interactions[j] ]
            ms.weights == :uniform || ( w[:] = df[ws, ms.weights] )
        end
    end
    # @ensure minimum( w ) > 0 || "specified weights must be positive"
    w /= sum( w )
    return GrumpsNodesWeights{T}( n, w )
end
