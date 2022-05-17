abstract type Space{T<:Flt} end
abstract type MarketSpace{T<:Flt} end
abstract type MicroSpace{T<:Flt} end
abstract type MacroSpace{T<:Flt} end 


struct GrumpsMicroNoSpace{T<:Flt} <: MicroSpace{T}
end

@todo 1 "remember: only stick stuff in space structs that gets reused"

struct GrumpsMicroSpace{T<:Flt} <: MicroSpace{T}
    πrij            ::  A3{T}
    πri             ::  A2{T}
    πi              ::  A1{T}
    ZXθ             ::  A3{T}
    lastδ           ::  A1{T}
    lastθ           ::  A1{T}
    mustrecompute   :: Bool


    function GrumpsMicroSpace( R :: Int, S :: Int, J :: Int, dθ :: Int, mustrecompute :: Bool, T2 :: Type = F64 )

        @ensure R > 0  "must have at least one draw"
        @ensure S > 0  "must have at least one consumer"
        @ensure J > 1 "must have at least one inside product"
        @ensure dθ > 0 "must have at least one theta coefficient"
        new{T2}( 
            zeros( T2, R, S, J ),
            zeros( T2, R, S ),
            zeros( T2, S ), 
            zeros( T2, R, S, J ),
            fill( typemax( T2 ), J - 1 ),
            fill( typemax( T2 ), dθ ),
            mustrecompute
            )
    end
end


GrumpsMicroSpace( d :: GrumpsMicroNoData{T}, mustrecompute :: Bool = false ) where {T<:Flt} = GrumpsMicroNoSpace{T}()
GrumpsMicroSpace( d :: GrumpsMicroData{T}, mustrecompute :: Bool = false ) where {T<:Flt} = GrumpsMicroSpace( dimR( d ), dimS( d ), dimJ( d ), dimθ( d ), mustrecompute, T )


@todo 4 "must reset lastδ every time a new θ is computed"


struct GrumpsMacroNoSpace{T<:Flt} <: MacroSpace{T}
end


struct GrumpsMacroSpace{T<:Flt} <: MacroSpace{T}
    Aθ              ::  A2{T}
    πrj             ::  A2{T}
    πj              ::  A1{T}
    ρ               ::  A1{T}
    ρπ              ::  A1{T}
    lastδ           ::  A1{T}
    lastθ           ::  A1{T}
    mustrecompute   ::  Bool

    function GrumpsMacroSpace( R :: Int, J :: Int, dθ :: Int, mustrecompute :: Bool, T2 :: Type = F64 )
        return new{T2}( 
            𝓏𝓈( T2, R, J ),     # Aθ
            𝓏𝓈( T2, R, J ),     # πrj
            𝓏𝓈( T2, J ),        # πj
            𝓏𝓈( T2, J ),        # ρ
            𝓏𝓈( T2, R ),        # ρπ
            𝓏𝓈( T2, J - 1 ),
            𝓏𝓈( T2, dθ ),
            mustrecompute
        )
    end
end


GrumpsMacroSpace( d :: GrumpsMacroNoData{T}, mustrecompute :: Bool ) where {T<:Flt} = GrumpsMacroNoSpace{T}()
GrumpsMacroSpace( d :: GrumpsMacroData{T}, mustrecompute :: Bool = false ) where {T<:Flt} = GrumpsMacroSpace( dimR( d ), dimJ( d ), dimθ( d ), mustrecompute, T )


struct GrumpsMarketSpace{T<:Flt} <: MarketSpace{T}
    microspace     :: GrumpsMicroSpace{T}
    macrospace     :: GrumpsMacroSpace{T}
    taken          :: Vec{Bool}
end



struct GrumpsSpace{T<:Flt} <: Space{T} 
    marketspace     :: Vec{ GrumpsMarketSpace{T} }
    currentθ        :: Vec{ T }
    memsave         :: Bool
end


memsave( s :: GrumpsSpace ) = s.memsave
marketspace( s :: GrumpsSpace, m :: Int ) = s.marketspace[m]

# struct GrumpsSpaceGreedy{T<:Flt} <: GrumpsSpace{T}
#     spc     :: A1{ GrumpsMarketSpace{T} }

#     function GrumpsSpaceGreedy( spc :: A1{ GrumpsMarketSpace{T2} } ) where {T2<:Flt}
#         return new{T2}( spc )
#     end
# end


# struct GrumpsSpaceFrugal{T<:Flt} <: GrumpsSpace{T}
#     spc     :: A1{ GrumpsMarketSpace{T} }
#     taken   :: A1{ Bool } 
# end



# function GrumpsSpace( d :: GrumpsData{T}, ::Val{ false }, nth :: Int ) where {T<:Flt}
#     return GrumpsSpaceGreedy( 
#         [ GrumpsMarketSpace{T}( 
#             GrumpsMicroSpace( d.microdata[m] ), 
#             GrumpsMacroSpace( d.macrodata[m] ) 
#             ) for m ∈ 1:dimM( d ) ] )
# end

function GrumpsSpace( d :: GrumpsData{T}, ::Val{ false }, nth :: Int ) where {T<:Flt}
    return GrumpsSpace{T}( [ GrumpsMarketSpace{T}( 
            GrumpsMicroSpace( d.marketdata[m].microdata, false ), 
            GrumpsMacroSpace( d.marketdata[m].macrodata, false ), 
            [false] 
            ) for m ∈ 1:dimM( d ) ],
            fill( typemax( T ), dimθ( d ) ),
            false )
end

@todo 2 "GrumpsSpace frugal memspace not yet implemented"

function GrumpsSpace( d :: GrumpsData{T}, ::Val{ true }, nth :: Int ) where {T<:Flt}
    @warn "GrumpsSpace frugal memspace not yet implemented"
end



GrumpsSpace( d :: GrumpsData{T}, o :: GrumpsOptimizationOptions ) where {T<:Flt} = GrumpsSpace( d, Val( memsave( o ) ), mktthreads( o ) )

