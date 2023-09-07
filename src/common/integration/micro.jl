


function show( io :: IO, ms :: DefaultMicroIntegrator; adorned = true )
    prstyled( adorned, "Default Micro quadrature integrator "; color = :blue, bold = true )
    println( "  $(ms.n) nodes per dimension")
end

function NodesWeightsOneDim64( ms :: DefaultMicroIntegrator{T}, nodes1 :: Int, precomputed ::Val{ true } ) :: Tuple{ Vector{T}, Vector{T} } where {T<:Flt}
    n1 = zeros( T, nodes1 ); w1 = similar( n1 )
    T == Float64 || @warn "Builtin Gauss Hermite weights are Float64; you specified $T"
    t = Arrow.Table( "$(@__DIR__)/data/gausshermite$(nodes1).arrow" )
    return T.( t.x ), T.( t.w )
end

function NodesWeightsOneDim64( ms :: DefaultMicroIntegrator{T}, nodes1 :: Int, ::Val{ :false } )  :: Tuple{ Vector{T}, Vector{T} } where {T<:Flt}
    n1, w1 = gausshermite( nodes1 );   n1 .*= sqrt(2.0);  w1 ./= sqrt(π)
    return n1, w1
end

function fillnw!( n::Matrix{T2}, w::Vector{T2}, combi::Vector{Int}, current::Int, nodes1 :: Int, d :: Int, n1 :: Vector{T2}, w1 :: Vector{T2} )::Nothing where {T2<:Flt}
    if current ≤ d
        for t ∈ 1:nodes1
            combi[current] = t 
            fillnw!( n, w, combi, current + 1, nodes1, d, n1, w1 )
        end
        return nothing
    end
    @assert( current == d + 1 )
    loc =  Int( sum( ( combi[j] -1 ) * nodes1^(j-1)  for j ∈ eachindex(combi) ) + 1 )
    w[loc] = prod( w1[combi[j]] for j ∈ eachindex(combi) )
    n[loc,:] = [ n1[combi[j]] for j ∈ eachindex(combi) ]
    return nothing
end


function NodesWeightsGlobal( ms :: DefaultMicroIntegrator{T}, d :: Int,  rng :: AbstractRNG ) where {T<:Flt}
   nodes1 = ms.n
   n1, w1 = NodesWeightsOneDim64( ms, nodes1, Val(  1 ≤ nodes1 ≤ 127 ) )                                                 # compute Gauss Hermite nodes and weights in a single dimension
   nodes = nodes1 ^ d                                                                                                      # total number of nodes
   w = ones( T, nodes )
   n = zeros( T, nodes, d )
   d == 0 && return ( n,w )
   
   fillnw!( n, w, zeros(Int, d ), 1, nodes1, d, n1, w1 )
   return GrumpsNodesWeights{T}(n, w)
end



function NodesWeightsOneMarket( ms :: DefaultMicroIntegrator{T}, d :: Int, rng :: AbstractRNG, nwgmic :: GrumpsNodesWeights{T}, S :: Int ) where {T<:Flt}
   return nwgmic
end


function NodesWeightsGlobal( ms :: MSMMicroIntegrator{T}, d :: Int,  rng :: AbstractRNG ) where {T<:Flt}
    return MSMMicroNodesWeights{T}( zeros( T, 0, 0, 0 ), zeros(T, 0, 0) )
 end
 

function NodesWeightsOneMarket( ms :: MSMMicroIntegrator{T}, d :: Int, rng :: AbstractRNG, nwgmic :: MSMMicroNodesWeights{T}, S :: Int ) where {T<:Flt}
    R = ms.n
    w = fill( T( 1.0/ R  ), R, S )
    n = randn( rng, R, S, d )
    return MSMMicroNodesWeights( n, w )
end
 