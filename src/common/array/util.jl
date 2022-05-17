
"""
    Symmetrize!( H :: AbstractMatrix{T} ) 

Fill the lower triangular of H with its upper triangular
"""
function Symmetrize!( H :: AA2{T} ) where {T<:Flt}
    d = size( H,1 )
    @ensure d == size( H, 2 )   "Matrix not square"
    @threads :dynamic for t ∈ 1:d
        for k ∈ t+1 : d
            H[ k, t ] = H[ t, k ]
        end
    end
    return nothing
end