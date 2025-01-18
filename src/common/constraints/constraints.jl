


function PrepareConstraint!( con :: Constraint{T}, d :: GrumpsData{T} ) where {T<:Flt}

    println( size( con.R ) )
    println( dimθ( d ) )
    @ensure size( con.R, 2) == dimθ( d ) "number of columns in constraints matrix must correspond to number of elements in θ"
    println( "R = $(con.R)" )
    con.Rtr = [ con.R[i,j] * d.balance[j].σ for i ∈ axes(con.R,1), j ∈ axes(con.R,2) ]
    println( "Rtr = $(con.Rtr)")
    con.A = nullspace( con.Rtr )
    println( "A = $(con.A)" )
    con.U = pinv( con.Rtr )
    println( "U = $(con.U)" )
    con.Ur = con.U * con.r
    println( "Ur = $(con.Ur)" )
    return nothing
end

