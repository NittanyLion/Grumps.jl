


function show( io :: IO, ms :: DefaultMacroIntegrator )
    print( "default macro integrator") 
end
 
function NodesWeightsGlobal( ms :: DefaultMacroIntegrator{T}, d :: Int,  draws :: Union{Nothing, DataFrame}, v :: Variables, rng :: AbstractRNG  ) where {T<:Flt}
   return GrumpsNodesWeights{T}( zeros( T, 0, 0 ), zeros(T, 0) )
end
 
 
 
function NodesWeightsOneMarket( ms :: DefaultMacroIntegrator{T}, dθν :: Int, df :: Union{Nothing, AbstractDataFrame}, v :: Variables, rng :: AbstractRNG, nwgmac :: GrumpsNodesWeights{T} ) where {T<:Flt}
    dθ = dθν + size( v.interactions, 1 ) 
    n = randn( rng, T, ms.n, dθ )
    if df ≠ nothing
        MustBeInDF( v.interactions[:,1], df, "draws" )
        @ensure ms.n ≤ nrow( df ) "Too few demographics draws.  This typically happens if the number of random draws specified for macro integration exceeds the number of demographics draws you have provided in the draws source"
        for j ∈ axes( v.interactions, 1 )
            n[ :, j ] = df[ 1:ms.n, v.interactions[j] ]
        end
    end
    w = fill( 1.0/ms.n, ms.n )
    return GrumpsNodesWeights{T}( n, w )
end