


value( ntr::NTR{T} ) where {T <: Flt} = ntr.F
gradient( ntr::NTR{T} ) where {T <: Flt} = ntr.DF
hessian( ntr::NTR{T} ) where {T <: Flt} = ntr.H


function value_add_penalty!!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    Kx = sum( ntr.K[m]' * x[m] for m ∈ eachindex(x) )
    ntr.F += dot( Kx, Kx ) * T(0.5)
end


# functions with two exclamation marks set stuff without checking if there is a repetition
function value!!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    # ntr.F = ntr.objfun( T(0.0), nothing, nothing, x, ntr.data ) 
    ntr.F = ntr.objfun( T(0.0), nothing, nothing, x ) 
    value_add_penalty!!( ntr, x )
    deepcopyto!( ntr.x_f, x)
    ntr.F
end

function gradient_add_penalty!!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    Kx = sum( ntr.K[m]' * x[m] for m ∈ eachindex(x) )
    for m ∈ eachindex( x )
        # local Kx  = ntr.K[m]' * x[m]
        ntr.DF[m][:] +=  ntr.K[m] * Kx
    end
end

function gradient!!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( ntr.x_df, x )
    ntr.objfun( nothing, ntr.DF, nothing, x )
    gradient_add_penalty!!( ntr, x )
    gradient( ntr )
end

function hessian!!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( ntr.x_h, x )
    ntr.objfun( nothing, nothing, ntr.H, x )
    hessian( ntr )
end


function value_gradient!!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    # computes both the value and the gradient
    deepcopyto!( ntr.x_f, x )
    deepcopyto!( ntr.x_df, x )
    ntr.F = ntr.objfun( T(0.0), gradient(ntr), nothing, x )
    value_add_penalty!!( ntr, x )
    gradient_add_penalty!!( ntr, x )
    ( value(ntr), gradient(ntr) )
end

function value!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, ntr.x_f ) || value!!( ntr, x )
    value( ntr )
end

function gradient!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, ntr.x_df ) || gradient!!( ntr, x )
    gradient( ntr )
end

function hessian!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, ntr.x_h ) || hessian!!( ntr, x )
    hessian( ntr )
end

function value_gradient!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    if !fullisequal( x, ntr.x_f) && !fullisequal( x, ntr.x_df )
        value_gradient!!( ntr, x )
    elseif !fullisequal( x, ntr.x_f )
        value!!( ntr, x )
    elseif !fullisequal( x, ntr.x_df )
        gradient!!( ntr, x )
    end
    ( value(ntr), gradient(ntr) )
end

function value_gradient_hessian!!( ntr::NTR{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( ntr.x_f, x )
    deepcopyto!( ntr.x_df, x )
    deepcopyto!( ntr.x_h, x )
    ntr.objfun( T(0.0), ntr.DF, ntr.H, x )
    value( ntr ), gradient( ntr ), hessian( ntr )
end




function fullhessian( ntr :: NTR{T} ) where {T<:Flt}
    dx = [ length( ntr.x_f[m] ) for m ∈ eachindex( ntr.x_f ) ]
    sumdx = sum( dx )
    H = zeros( T, sumdx, sumdx )
    for m ∈ eachindex( ntr.x_f )
        H[ ntr.ranges[m], ntr.ranges[m] ] = ntr.H[m]
    end
    for m ∈ eachindex( ntr.x_f )
        for mm ∈ eachindex( ntr.x_f )
            H[ ntr.ranges[m], ntr.ranges[mm] ] += ntr.K[m] * ntr.K[mm]'
        end
    end
    H
end




