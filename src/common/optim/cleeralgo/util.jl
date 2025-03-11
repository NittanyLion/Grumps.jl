
#

function deepcopyto!( dest::VVector{T}, src::VVector{T} ) where {T<:Flt}
    for i ∈ eachindex( src )
        copyto!( dest[i], src[i] )
    end
end




function fullisequal( x::AbstractArray, y::AbstractArray )
    length( x ) == length( y ) || return false
    for i ∈ eachindex( x )
        x[i] == y[i] || return false
    end
    true
end

