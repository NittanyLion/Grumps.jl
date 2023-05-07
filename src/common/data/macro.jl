# The function below produces a data object used for processing the macro likelihood.



"""
    GrumpsMacroData( 
        id          :: Any,
        mkt         :: AbstractString,
        N           :: Real,
        dfp         :: AbstractDataFrame,
        v           :: Variables,
        nw          :: NodesWeights,
        mic         :: Union{Nothing, GrumpsMicroData},
        options     :: DataOptions,
        T           :: sType = F64
        )

Creates the macro data object to be used by Grumps.  This function should not be called directly.  Just call `Data` or `GrumpsData` (which are synonymous) instead.
"""
function GrumpsMacroData( id :: Any, mkt :: AbstractString, N :: Real, dfp :: AbstractDataFrame, v :: Variables, nw :: NodesWeights, mic :: Union{Nothing, MicroData}, options :: DataOptions, T::Type = F64 )

    J = nrow( dfp ) + 1
    dθ = size( nw.nodes, 2 )
    dθz = size( v.interactions, 1 )
    𝒳 = zeros( T, J, dθ )

    MustBeInDF( vcat( v.interactions[:,2], v.randomcoefficients, v.share ), dfp, "products" )

    for j ∈ 1:nrow( dfp )
        for t ∈ 1:dθz
            𝒳[ j, t ] = T( dfp[ j, v.interactions[t,2] ] )
        end
        for t ∈ eachindex( v.randomcoefficients )
            𝒳[ j, t+dθz ] = T( dfp[ j, v.randomcoefficients[t] ] )
        end
    end
    Ns = N * vcat( T.( dfp[ :, v.share ] ), T( 1.0 - sum( dfp[:, v.share ] ) ) )
    S = typeof(mic) ∈ [ Nothing, GrumpsMicroNoData{T} ] ? 0 : length( mic.y )
    N -= S
    shares = typeof(mic) ∈ [ Nothing, GrumpsMicroNoData{T} ] ? Ns / N : [ Ns[j] - sum( mic.Y[:,j] ) for j ∈ 1:J ] / N
    @ensure all( shares .≥ 0.0 ) "macro shares must be nonnegative in market $mkt; can be negative if there are more micro sample consumers purchasing than are in the population, which would be weird"
    if options.macromode == :Ant
        return GrumpsMacroDataAnt{T}( String( mkt ), 𝒳, T.( nw.nodes ), shares, T( N ), T.( nw.weights ) )
    else
        @ensure options.macromode == :Hog "unknown memory mode $(options.mode)"
        𝒜 = [ T( nw.nodes[r,t] * 𝒳[j,t] ) for r ∈ axes( nw.nodes,1), j ∈ axes(𝒳, 1),  t ∈ axes( nw.nodes, 2) ]
        return GrumpsMacroHog{T}( String( mkt ), 𝒜, s, N, T.( nw.weights) )
    end
end

MacroData(x...; y...) = GrumpsMacroData(x...; y...) 
export MacroData
