

abstract type AbstractConstraint{T<:Flt} end

struct NoConstraint{T} <: AbstractConstraint{T}
end



mutable struct Constraint{T<:Flt} <: AbstractConstraint{T}
    R       ::    A2{T}
    r       ::    A1{T}
    Rtr     ::    A2{T}
    U       ::    A2{T}
    Ur      ::    A1{T}
    A       ::    A2{T}



    function Constraint( R :: A2{T2}, r :: A1{T2} ) where {T2<:Flt}
        @ensure size( R,1 ) == length( r ) "number of rows in constraints matrix differs from number of elements in constraints vector (Rθ≠r)"
        @ensure rank( R ) == size( R, 1) "restrictions matrix does not have full rank"
        new{T2}( R, r, similar( R ), zeros(T,0,0), zeros(T, 0, 0), zeros(T, 0), zeros(T,0,0) )
    end
end

Constrained(  c :: AbstractConstraint{T} ) where T<:Flt = typeof( c ) == Constraint{T}


dim( c :: Constraint{T} ) where T<:Flt = size( c.R, 1 )
dim( c :: NoConstraint{T} ) where T<:Flt = 0

