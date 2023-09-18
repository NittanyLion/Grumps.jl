import LinearAlgebra.dot

function grumps_dot( u::VVector{T}, v::VVector{T} ) where {T<:Flt}
    @assert( length( u ) == length( v ) )
    sum( dot( u[m], v[m] ) for m ∈ eachindex( u ) )
end


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




function minmax( v::VVector{T} ) where {T<:Flt}
    mi, ma = typemax( T ), typemin( T )
    for x ∈ v
        mi = min( mi, minimum( x ) )
        ma = max( ma, maximum( x ) )
    end
    mi, ma
end     


function ntr_infs( T, J :: Vector{Int} )
    [ fill( typemax( T ), J[m] ) for m ∈ eachindex( J ) ]
end

function ntr_infs_mat( T, J :: Vector{Int} )
    [ fill( typemax(T), J[m], J[m] ) for m ∈ eachindex( J ) ]
end


function grumps_isfinite( H::Vector{Matrix{T}} ) where {T<:Flt}
    for A ∈ H
        all( isfinite, A ) || return false
    end
    true
end


# to be moved to basics / util.jl
function binaryrun( f, left, right, units, U )
    units = max( units, 1 )
    if right - left < units return f( left, right, U ) end
    middle = div( left + right, 2)
    lefty = @spawn binaryrun( f, left, middle, units, U )
    binaryrun( f, middle+1, right, units, U )
    fetch( lefty )
    return nothing
end



function ntr_update_trace!( tr :: NTRTrace{T}, iteration, f, x, gnorm, dt ) where {T<:Flt}
    push!( tr.tr, NTRTrace1( iteration, f, x, gnorm, dt ) )
end



function show( io :: IO, ntr :: NTR{T} ) where {T<:Flt}
    printstyled(" current contents of ntr are\n "; bold=true, color =:magenta)
    println( ntr.F )
    println( ntr.x_f )
    println( ntr.x_df )
    println( ntr.x_h )
    println( ntr.DF )
end


function show( io :: IO, state :: NTRState{T} ) where {T<:Flt}
    printstyled(" current contents of state are\n "; bold=true, color =:magenta)
    println( state.f_x_previous )
    println( state.x_previous )
    println( state.g_previous )
end

