


value( newt::Newter{T} ) where {T <: Flt} = newt.F
gradient( newt::Newter{T} ) where {T <: Flt} = newt.DF
hessian( newt::Newter{T} ) where {T <: Flt} = newt.H


function value_add_penalty!!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    Kx = sum( newt.K[m]' * x[m] for m ∈ eachindex(x) )
    newt.F += dot( Kx, Kx ) * T(0.5)
end


# functions with two exclamation marks set stuff without checking if there is a repetition
function value!!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    # newt.F = newt.objfun( T(0.0), nothing, nothing, x, newt.data ) 
    newt.F = newt.objfun( T(0.0), nothing, nothing, x ) 
    value_add_penalty!!( newt, x )
    deepcopyto!( newt.x_f, x)
    newt.F
end

function gradient_add_penalty!!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    Kx = sum( newt.K[m]' * x[m] for m ∈ eachindex(x) )
    for m ∈ eachindex( x )
        # local Kx  = newt.K[m]' * x[m]
        newt.DF[m][:] +=  newt.K[m] * Kx
    end
end

function gradient!!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( newt.x_df, x )
    newt.objfun( nothing, newt.DF, nothing, x )
    gradient_add_penalty!!( newt, x )
    gradient( newt )
end

function hessian!!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( newt.x_h, x )
    newt.objfun( nothing, nothing, newt.H, x )
    hessian( newt )
end


function value_gradient!!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    # computes both the value and the gradient
    deepcopyto!( newt.x_f, x )
    deepcopyto!( newt.x_df, x )
    newt.F = newt.objfun( T(0.0), gradient(newt), nothing, x )
    value_add_penalty!!( newt, x )
    gradient_add_penalty!!( newt, x )
    ( value(newt), gradient(newt) )
end

function value!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, newt.x_f ) || value!!( newt, x )
    value( newt )
end

function gradient!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, newt.x_df ) || gradient!!( newt, x )
    gradient( newt )
end

function hessian!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, newt.x_h ) || hessian!!( newt, x )
    hessian( newt )
end

function value_gradient!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    if !fullisequal( x, newt.x_f) && !fullisequal( x, newt.x_df )
        value_gradient!!( newt, x )
    elseif !fullisequal( x, newt.x_f )
        value!!( newt, x )
    elseif !fullisequal( x, newt.x_df )
        gradient!!( newt, x )
    end
    ( value(newt), gradient(newt) )
end

function value_gradient_hessian!!( newt::Newter{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( newt.x_f, x )
    deepcopyto!( newt.x_df, x )
    deepcopyto!( newt.x_h, x )
    newt.objfun( T(0.0), newt.DF, newt.H, x )
    value( newt ), gradient( newt ), hessian( newt )
end




function fullhessian( newt :: Newter{T} ) where {T<:Flt}
    dx = [ length( newt.x_f[m] ) for m ∈ eachindex( newt.x_f ) ]
    sumdx = sum( dx )
    H = zeros( T, sumdx, sumdx )
    for m ∈ eachindex( newt.x_f )
        H[ newt.ranges[m], newt.ranges[m] ] = newt.H[m]
    end
    for m ∈ eachindex( newt.x_f )
        for mm ∈ eachindex( newt.x_f )
            H[ newt.ranges[m], newt.ranges[mm] ] += newt.K[m] * newt.K[mm]'
        end
    end
    H
end




