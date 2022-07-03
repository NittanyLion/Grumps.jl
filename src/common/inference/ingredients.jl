








abstract type Ingredients{T<:Flt} end





dimM( ii :: Ingredients ) = length( ii.ranges )

function VarianceSum( X :: AA2{T}, ξ :: AA1{T}, Y :: AA2{T}, ::Val{:homo} )  where {T<:Flt}
    @ensure size(X,1) == size( Y, 1 ) == length( ξ )  "size mismatch" 
    σξ2 = sum( ξ[i]^2 for i ∈ eachindex(ξ) ) / length( ξ )
    return σξ2 * X'Y
end

function VarianceSum( X :: AA2{T}, ξ :: AA1{T}, Y :: AA2{T}, ::Val{:hetero} )  where {T<:Flt}
    @ensure size(X,1) == size( Y, 1 ) == length( ξ )  "size mismatch" 
    return [ sum( X[r,i] * ξ[r]^2 * Y[r,j] for r ∈ eachindex( ξ ) ) for i ∈ axes(X,2), j ∈ axes(Y,2) ]
end



