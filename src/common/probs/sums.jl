function ComputeΣππ( 
    s       :: MicroSpace{T}, 
    d       :: GrumpsMicroData{T}, 
    o       :: OptimizationOptions 
    ) where {T<:Flt}


    weights, consumers, products, insides, = RSJ( d )
    return [ sum( d.w[r] * s.πri[r,i] * s.πrij[r,i,k] for r ∈ weights ) for i ∈ consumers, k ∈ products ]
end

function ComputeΣππ( 
    s       :: MacroSpace{T}, 
    d       :: GrumpsMacroData{T}, 
    o       :: OptimizationOptions 
    ) where {T<:Flt}

    weights, products, insides,  = RJ( d )
    return  [ sum( d.w[r] * s.πrj[r,j] * s.πrj[r,k] for r ∈ weights ) for j ∈ products, k ∈ insides  ]
end







function ComputeΔb!( Δb :: AA2{T}, s :: MicroSpace{T}, d :: GrumpsMicroDataHog{T}, o :: OptimizationOptions, r :: Int, i :: Int ) where {T<:Flt}
    weights, consumers, products, insides, = RSJ( d )
    @ensure r ∈ weights         "weights out of bounds"
    @ensure i ∈ consumers       "consumers out of bounds"
    @ensure size( Δb, 1 ) == products[end]  "mismatch in the number of products in Δb"
    @ensure size( Δb, 2 ) == dimθ( d )  "mismatch in the number of parameters in Δb"


    for k ∈ 1:dimθz( d )
        avg = sum( s.πrij[r,i,j] * d.Z[i,j,k] for j ∈ products )
        for j ∈ products
            Δb[ j, k ] = d.Z[i,j,k] - avg
        end
    end

    for k ∈ 1:dimθν( d )
        kk = k + dimθz( d )
        avg = sum( s.πrij[r,i,j] * d.X[r,j,k] for j ∈ products )
        for j ∈ products
            Δb[ j, kk ] = d.X[r,j,k] - avg
        end
    end        

    return nothing
end

function ComputeΔb!( Δb :: AA2{T}, s :: MicroSpace{T}, d :: MSMMicroDataHog{T}, o :: OptimizationOptions, r :: Int, i :: Int ) where {T<:Flt}
    weights, consumers, products, insides, = RSJ( d )
    @ensure r ∈ weights         "weights out of bounds"
    @ensure i ∈ consumers       "consumers out of bounds"
    @ensure size( Δb, 1 ) == products[end]  "mismatch in the number of products in Δb"
    @ensure size( Δb, 2 ) == dimθ( d )  "mismatch in the number of parameters in Δb"


    for k ∈ 1:dimθz( d )
        avg = sum( s.πrij[r,i,j] * d.Z[i,j,k] for j ∈ products )
        for j ∈ products
            Δb[ j, k ] = d.Z[i,j,k] - avg
        end
    end

    for k ∈ 1:dimθν( d )
        kk = k + dimθz( d )
        avg = sum( s.πrij[r,i,j] * d.X[r,i,j,k] for j ∈ products )
        for j ∈ products
            Δb[ j, kk ] = d.X[r,i,j,k] - avg
        end
    end        

    return nothing
end

function ComputeΔb!( Δb :: AA2{T}, s :: MicroSpace{T}, d :: MicroData, o :: OptimizationOptions, r :: Int, i :: Int ) where {T<:Flt}
    weights, consumers, products, insides, parameters = RSJ( d )
    @ensure false "WeightedDifference! not yet programmed for $(typeof(d))"
end


function ComputeΔa!( Δa :: AA2{T}, s :: MacroSpace{T}, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions, r :: Int ) where {T<:Flt}
    weights, products, insides, parameters = RJ( d )

    Δa .= zero( T )
    for k ∈ parameters
        avg = sum( s.πrj[r,j] * d.𝒳[j,k] for j ∈ products )
        for j ∈ products
            Δa[j,k] = d.𝒟[r,k] * ( d.𝒳[j,k] - avg )
        end
    end
    return nothing
end