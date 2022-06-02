# the stored gradients and hessians are the narrow ones, i.e.
# they do *not* contain the penalty term

const VVector{T} = Vector{ Vector{T} }
const VMatrix{T} = Vector{ Matrix{T} }


struct NTRMethod{T<:Flt}
    ρ_lower     :: T
    ρ_upper     :: T
    Δhat        :: T
    initial_Δ   :: T
    η           :: T

    function NTRMethod( ρl :: T2, ρu :: T2, Δh :: T2, iΔ :: T2, η :: T2 ) where {T2<:Flt}
        new{T2}( ρl, ρu, Δh, iΔ, η )
    end
end

const VVector{T} = Vector{ Vector{T} }
const VMatrix{T} = Vector{ Matrix{T} }
const FVType{T} = Union{ Nothing, Vector{T} }
const GVType{T} = Union{ Nothing, VVector{T} }
const HVType{T} = Union{ Nothing, VMatrix{T} }

mutable struct NTRState{T<:Flt}
    x_previous      :: VVector{T} 
    x               :: VVector{T} 
    f_x_previous    :: T
    s               :: VVector{T} 
    g_previous      :: VVector{T} 
    Δ               :: T
    ρ               :: T
    λ               :: T
    η               :: T
    interior        :: Bool
    reached_subproblem_solution :: Bool

    function NTRState( x_previous :: VVector{T2}, x :: VVector{T2}, f_x_previous :: T2, s :: VVector{T2},
                       g_previous :: VVector{T2}, Δ :: T2, ρ :: T2, λ :: T2, η :: T2, interior :: Bool, rss :: Bool ) where {T2<:Flt}
        new{T2}( x_previous, x, f_x_previous, s, g_previous, Δ, ρ, λ, η, interior, rss )
    end
end


struct NTROptions{T<:Flt}
    initial_Δ    :: T 
    Δhat        :: T 
    η           :: T
    ρ_lower     :: T 
    ρ_upper     :: T 
    x_abs_tol   :: T 
    g_abs_tol   :: T 
    f_rel_tol   :: T   
    iterations  :: Int
    extended_trace :: Bool 
    show_trace  :: Bool

    function NTROptions( T = Float64; initial_Δ =1.0, Δhat = 100.0, η = 0.1, ρ_lower = 0.25, ρ_upper = 0.75, 
                         x_abs_tol = 0.0, g_abs_tol = 1.0e-8, f_rel_tol = 0.0, iterations = 50, 
                         extended_trace = true, show_trace = true )
        new{T}( T(initial_Δ), T( Δhat ), T( η ), T( ρ_lower ), T( ρ_upper ), 
                T( x_abs_tol ), T( g_abs_tol ), T( f_rel_tol ), iterations,
                extended_trace, show_trace )
    end
end



mutable struct NTR{T<:Flt}
    F               :: T
    DF              :: VVector{T} 
    H               :: VMatrix{T} 
    K               :: VMatrix{T} 
    x_f             :: VVector{T}     # value at which we last computed the objective function
    x_df            :: VVector{T}     # value at which we last computed the gradient
    x_h             :: VVector{T}     # value at which we last computed the Hessian
    objfun          :: Function
    ranges          :: Vector{ UnitRange{Int} }
    data            :: Vector{ GrumpsMarketData{T} }
    function NTR( f :: Function, xstart :: VVector{T2}, data :: Vector{GrumpsMarketData{T2}}, K :: VMatrix{T2} ) where {T2<:Flt}
        J = [ length( xstart[m] ) for m ∈ eachindex( xstart ) ]
        new{T2}( 
            typemax(T2),
            ntr_infs( T2, J ),
            ntr_infs_mat( T2, J),
            deepcopy( K ),
            ntr_infs( T2, J ),
            ntr_infs( T2, J ),
            ntr_infs( T2, J ),
            f,
            Ranges( J ),
            data
         )
    end
end



struct PLMSpace{T<:Flt}
    som         :: VVector{T}
    Z           :: VMatrix{T}

    function PLMSpace( dδ :: Vector{Int}, dk :: Int, T2 = Float64 )
        M = length(dδ);  markets = 1:M
        som = [ zeros( T2, dδ[m] ) for m ∈ markets ] 
        Z = [ zeros(T2, dk, dδ[m]) for m ∈ markets ]
        new{T2}( som, Z )
    end
end

struct NTRTrace1{T<:Flt} 
    iteration   :: Int
    f           :: T
    x           :: VVector{T}
    gnorm       :: T
    dt          :: Dict
    function NTRTrace1( iteration :: Int, f::T2, x :: VVector{T2}, gnorm :: T2, dt :: Dict ) where {T2<:Flt}
        new{T2}( iteration, f, x, gnorm, dt )
    end
end



mutable struct NTRTrace{T<:Flt} 
    tr          :: Vector{ NTRTrace1{T} }
    starttime   :: Float64

    function NTRTrace( T )
        new{T}( VVector{ NTRTrace1{T} }(undef, 0), time() )
    end
end


# mutable struct NTRFGH{T<:Flt}
#     f           :: T
#     g           :: Vector{T}        # this is the full one
#     H           :: VMatrix{T}        
#     x           :: Vector{T}
#     # status      :: Symbol
#     function NTRFGH( ntr :: NTR{T2} ) where {T2<:Flt}
#         markets = 1:length( ntr.x_f )
#         dδ = [ length( ntr.x_f[m] ) for m ∈ markets ]
#         dim = sum( dδ )
#         new{T2}( typemax(T2),  zeros( T2, dim ), [ zeros( T2, dδ[m], dδ[m] ) for m ∈ markets ], zeros( T2, dim ) )
#     end
#     function NTRFGH( T2::Type, dδ :: Int )
#         new{T2}( typemax(T2),  zeros( T2, dim ), [ zeros( T2, dδ[m], dδ[m] ) for m ∈ markets ], zeros( T2, dim ) )
#     end
# end    


