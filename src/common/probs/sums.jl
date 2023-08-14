function ComputeΣππ( 
    s       :: MicroSpace{T}, 
    d       :: GrumpsMicroData{T}, 
    o       :: OptimizationOptions,
    loopvectorization :: Val{ false } 
    ) :: Matrix{T} where {T<:Flt}


    weights, consumers, products, insides, = RSJ( d )
    return [ sum( d.w[r] * s.πri[r,i] * s.πrij[r,i,k] for r ∈ weights ) for i ∈ consumers, k ∈ products ]
end

function ComputeΣππ( 
    s       :: MicroSpace{T}, 
    d       :: GrumpsMicroData{T}, 
    o       :: OptimizationOptions,
    loopvectorization :: Val{ true }  
    ) :: Matrix{T} where {T<:Flt}
        
    @tullio fastmath=false Σππ[i,k] := d.w[r] * s.πri[r,i] * s.πrij[r,i,k]
    return Σππ
end

function ComputeΣππ( 
    s       :: MicroSpace{T}, 
    d       :: GrumpsMicroData{T}, 
    o       :: OptimizationOptions 
    ) :: Matrix{T} where {T<:Flt} 
    
    return ComputeΣππ( s, d, o, Val( o.loopvectorization ) ) 
end



function ComputeΣππ( 
    s       :: MacroSpace{T}, 
    d       :: GrumpsMacroData{T}, 
    o       :: OptimizationOptions,
    loopvectorization :: Val{ false } 
    ) where {T<:Flt}

    return [ sum( d.w[r] * s.πrj[r,j] * s.πrj[r,k] for r ∈ eachindex( d.w ) ) for j ∈ 1:dimJ( d ), k ∈ 1:dimδ( d ) ]
end


function ComputeΣππ( 
    s       :: MacroSpace{T}, 
    d       :: GrumpsMacroData{T}, 
    o       :: OptimizationOptions,
    loopvectorization :: Val{ true } 
    ) :: Matrix{T} where {T<:Flt}

    Σππ = zeros( T, dimJ( d ), dimδ( d ) )
    @tullio fastmath=false Σππ[j,k] = d.w[r] * s.πrj[r,j] * s.πrj[r,k+0]

    return Σππ
end


function ComputeΣππ( s :: MacroSpace{T}, d :: GrumpsMacroData{T}, o :: OptimizationOptions ) :: Matrix{T} where {T<:Flt} 
    return ComputeΣππ( s, d, o, Val( o.loopvectorization ) )
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


# function ComputeΔa( s :: MacroSpace{T}, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions ) where {T<:Flt}
#     weights, products, insides, parameters = RJ( d )

#     avg = s.πrj * d.𝒳 
#     @tullio fastmath=false Δa[r,j,k] := d.𝒟[r,k] * ( d.𝒳[j,k] - avg[r,k] )
#     return Δa
# end

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



# function ComputeΔa!( Δa :: AA2{T}, s :: MacroSpace{T}, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions, r :: Int ) where {T<:Flt}
#     weights, products, insides, parameters = RJ( d )

#     @tullio fastmath=false avg[k] := s.πrj[$r,j] * d.𝒳[j,k]
#     @tullio fastmath=false Δa[j,k] = d.𝒟[$r,k] * ( d.𝒳[j,k] - avg[k] )
#     return nothing
# end