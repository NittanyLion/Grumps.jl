
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


function colspace(A::AbstractVecOrMat; atol::Real = 0.0, rtol::Real = (min(size(A, 1), size(A, 2))*eps(real(float(oneunit(eltype(A))))))*iszero(atol))
    m, n = size(A, 1), size(A, 2)
    (m == 0 || n == 0) && return Matrix{eigtype(eltype(A))}(I, n, n)
    SVD = svd(A; full=false)
    tol = max(atol, SVD.S[1]*rtol)
    indend = sum(s -> s .> tol, SVD.S) 
    return copy((@view SVD.U[:,1:indend]))
end



function HasMaximumColumnRank( A; ε = 1.0e-8 )
    B = copy( A )
    foreach( normalize!, eachcol( B ) )
    return rank( B; atol = ε ) == size( A, 2 )
end

