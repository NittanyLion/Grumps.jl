


function show( io :: IO, ms :: DefaultMicroSampler )
   print( "default micro sampler") 
end


function NodesWeightsGlobal( ms :: DefaultMicroSampler{T}, d :: Int,  rng :: AbstractRNG ) where {T<:Flt}
   nodes1 = ms.n
   (n1, w1 ) = gausshermite( nodes1 );  n1 .*= sqrt(2.0);  w1 ./= sqrt(π)                                                  # compute Gauss Hermite nodes and weights in a single dimension
   nodes = nodes1 ^ d                                                                                                      # total number of nodes
   w = ones( T, nodes )
   n = zeros( T, nodes, d )
   d == 0 && return ( n,w )
   
   function fillnw( n::Matrix{T2}, w::Vector{T2}, combi::Vector{Int}, current::Int )::Nothing where {T2<:Flt}
      if current ≤ d
          for t ∈ 1:nodes1
              combi[current] = t 
              fillnw( n, w, combi, current + 1)
          end
          return nothing
      end
      @assert( current == d + 1 )
      loc =  Int( sum( ( combi[j] -1 ) * nodes1^(j-1)  for j ∈ eachindex(combi) ) + 1 )
      w[loc] = prod( w1[combi[j]] for j ∈ eachindex(combi) )
      n[loc,:] = [ n1[combi[j]] for j ∈ eachindex(combi) ]
      nothing
  end
  fillnw( n, w, zeros(Int, d ), 1 )
  return GrumpsNodesWeights{T}(n, w)
end



function NodesWeightsOneMarket( ms :: DefaultMicroSampler{T}, d :: Int, rng :: AbstractRNG, nwgmic :: GrumpsNodesWeights{T} ) where {T<:Flt}
   return nwgmic
end