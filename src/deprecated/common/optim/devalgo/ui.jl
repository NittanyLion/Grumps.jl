


value( 🦎::Newter{T} ) where {T <: Flt} = 🦎.F
gradient( 🦎::Newter{T} ) where {T <: Flt} = 🦎.DF
hessian( 🦎::Newter{T} ) where {T <: Flt} = 🦎.H
Kmat( 🦎::Newter{T} ) where {T<:Flt} = 🦎.K

function value_add_penalty!!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    Kx = sum( 🦎.K[m]' * x[m] for m ∈ eachindex(x) )
    🦎.F += dot( Kx, Kx ) * T(0.5)
end


# functions with two exclamation marks set stuff without checking if there is a repetition
function value!!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    # 🦎.F = 🦎.objfun( T(0.0), nothing, nothing, x, 🦎.data ) 
    🦎.F = 🦎.objfun( T(0.0), nothing, nothing, x ) 
    value_add_penalty!!( 🦎, x )
    deepcopyto!( 🦎.x_f, x)
    🦎.F
end

function gradient_add_penalty!!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    Kx = sum( 🦎.K[m]' * x[m] for m ∈ eachindex(x) )
    for m ∈ eachindex( x )
        # local Kx  = 🦎.K[m]' * x[m]
        🦎.DF[m][:] +=  🦎.K[m] * Kx
    end
end

function gradient!!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( 🦎.x_df, x )
    🦎.objfun( nothing, 🦎.DF, nothing, x )
    gradient_add_penalty!!( 🦎, x )
    gradient( 🦎 )
end

function hessian!!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( 🦎.x_h, x )
    🦎.objfun( nothing, nothing, 🦎.H, x )
    hessian( 🦎 )
end


function value_gradient!!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    # computes both the value and the gradient
    deepcopyto!( 🦎.x_f, x )
    deepcopyto!( 🦎.x_df, x )
    🦎.F = 🦎.objfun( T(0.0), gradient(🦎), nothing, x )
    value_add_penalty!!( 🦎, x )
    gradient_add_penalty!!( 🦎, x )
    ( value(🦎), gradient(🦎) )
end

function value!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, 🦎.x_f ) || value!!( 🦎, x )
    value( 🦎 )
end

function gradient!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, 🦎.x_df ) || gradient!!( 🦎, x )
    gradient( 🦎 )
end

function hessian!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    fullisequal( x, 🦎.x_h ) || hessian!!( 🦎, x )
    hessian( 🦎 )
end

function value_gradient!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    if !fullisequal( x, 🦎.x_f) && !fullisequal( x, 🦎.x_df )
        value_gradient!!( 🦎, x )
    elseif !fullisequal( x, 🦎.x_f )
        value!!( 🦎, x )
    elseif !fullisequal( x, 🦎.x_df )
        gradient!!( 🦎, x )
    end
    ( value(🦎), gradient(🦎) )
end

function value_gradient_hessian!!( 🦎::Newter{T}, x::VVector{T} ) where {T<:Flt}
    deepcopyto!( 🦎.x_f, x )
    deepcopyto!( 🦎.x_df, x )
    deepcopyto!( 🦎.x_h, x )
    🦎.objfun( T(0.0), 🦎.DF, 🦎.H, x )
    value( 🦎 ), gradient( 🦎 ), hessian( 🦎 )
end




function fullhessian( 🦎 :: Newter{T} ) where {T<:Flt}
    dx = [ length( 🦎.x_f[m] ) for m ∈ eachindex( 🦎.x_f ) ]
    sumdx = sum( dx )
    H = zeros( T, sumdx, sumdx )
    for m ∈ eachindex( 🦎.x_f )
        H[ 🦎.ranges[m], 🦎.ranges[m] ] = 🦎.H[m]
    end
    for m ∈ eachindex( 🦎.x_f )
        for mm ∈ eachindex( 🦎.x_f )
            H[ 🦎.ranges[m], 🦎.ranges[mm] ] += 🦎.K[m] * 🦎.K[mm]'
        end
    end
    H
end




