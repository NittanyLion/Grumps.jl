


function PrepareConstraint!( con :: Constraint{T}, d :: GrumpsData{T} ) where {T<:Flt}

    @ensure size( con.R, 2) == dimθ( d ) "number of columns in constraints matrix must correspond to number of elements in θ"
    con.Rtr = [ con.R[i,j] * gd.balance[j].σ for i ∈ axes(con.R,1), j ∈ axes(con.R,2) ]
    con.A = nullspace( con.Rtr' )
    con.U = pinv( con.Rtr )
    con.Ur = con.U * con.r
    return nothing
end

