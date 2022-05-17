


function GrumpsMacroData( mkt :: AbstractString, N :: Real, dfp :: AbstractDataFrame, v :: Variables, nw :: NodesWeights, mic :: Union{Nothing, GrumpsMicroData}, options :: DataOptions, T::Type = F64, u :: UserEnhancement = DefaultUserEnhancement() )
    @ensure typeof( u ) == DefaultUserEnhancement  "cannot yet deal with $(typeof(u))"

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
    S = mic == nothing ? 0 : length( mic.y )
    N -= S
    shares = mic == nothing ? Ns / N : [ Ns[j] - sum( mic.Y[:,j] ) for j ∈ 1:J ] / N
    @ensure all( shares .≥ 0.0 ) "macro shares must be nonnegative in market $mkt; can be negative if there are more micro sample consumers purchasing than are in the population "
    if options.macromode == :Ant
        return GrumpsMacroDataAnt{T}( String( mkt ), 𝒳, T.( nw.nodes ), shares, T( N ), T.( nw.weights ) )
    else
        @ensure options.macromode == :Hog "unknown memory mode $(options.mode)"
        𝒜 = [ T( nw.nodes[r,t] * 𝒳[j,t] ) for r ∈ axes( nw.nodes,1), j ∈ axes(𝒳, 1),  t ∈ axes( nw.nodes, 2) ]
        return GrumpsMacroHog{T}( String( mkt ), 𝒜, s, N, T.( nw.weights) )
    end
end


