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

    function GrumpsMicroSpace( x::A3{T2}, y... ) where {T2<:Flt}
        new{T2}( x, y... )
    end

end


function MicroSpaceArraysNeeded( R :: Int, S :: Int, J :: Int, dθ :: Int )
    return [ 
        ( R,  S,  J );        # πrij
        ( R, S );             # πri
        ( S );                # πi
        ( R, S, J );          # ZXθ
        ( J - 1 );            # lastδ
        ( dθ )                # lastθ  
        ]
end


function MicroSpaceNeeded( R :: Int, S :: Int, J :: Int, dθ :: Int )
    tups = MicroSpaceArraysNeeded( R, S, J, dθ )
    return sum( prod( t ) for t ∈ tups )
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
            zeros( T2, R, J ),     # Aθ
            zeros( T2, R, J ),     # πrj
            zeros( T2, J ),        # πj
            zeros( T2, J ),        # ρ
            zeros( T2, R ),        # ρπ
            zeros( T2, J - 1 ),
            zeros( T2, dθ ),
            mustrecompute
        )
    end

    function GrumpsMacroSpace( x::A2{T2}, y... ) where {T2<:Flt}
        new{T2}( x, y... )
    end
end


function MacroSpaceArraysNeeded( R :: Int, J :: Int, dθ :: Int )
    return   [
        ( R, J );        # Aθ
        ( R, J );        # πrj
        ( J );           # πj
        ( J );           # ρ
        ( R );           # ρπ
        ( J - 1 );       # lastδ
        ( dθ )           # lastθ
    ]
end


function MacroSpaceNeeded( R :: Int, J :: Int, dθ :: Int )
    tups = MacroSpaceArraysNeeded( R, J, dθ )
    return sum( prod( t ) for t ∈ tups )
end


function SpaceArraysNeeded( Rmic :: Int, Rmac :: Int, S :: Int, J :: Int, dθ :: Int )
    return vcat( MicroSpaceArraysNeeded( Rmic, S, J, dθ ), MacroSpaceArraysNeeded( Rmac, J, dθ ) )
end





GrumpsMacroSpace( d :: GrumpsMacroNoData{T}, mustrecompute :: Bool ) where {T<:Flt} = GrumpsMacroNoSpace{T}()
GrumpsMacroSpace( d :: GrumpsMacroData{T}, mustrecompute :: Bool = false ) where {T<:Flt} = GrumpsMacroSpace( dimR( d ), dimJ( d ), dimθ( d ), mustrecompute, T )


const NoMemblockIndex = typemin( Int )

struct GrumpsMarketSpace{T<:Flt} <: MarketSpace{T}
    microspace     :: MicroSpace{T}
    macrospace     :: MacroSpace{T}
    memblockindex  :: Int
end

# struct GrumpsMarketSpace{T<:Flt} <: MarketSpace{T}
#     microspace     :: GrumpsMicroSpace{T}
#     macrospace     :: GrumpsMacroSpace{T}
#     memblockindex  :: Int
# end

function GrumpsMarketSpace( d :: GrumpsMarketData{T}, memblock :: MemBlock{T}, m :: Int ) where {T<:Flt}
    b = memblock.revdiv[m]          # which memory block are we using?
    p = pointer( memblock.mem[b] )
    tups = SpaceArraysNeeded( dimR( d.microdata ), dimR( d.macrodata ), dimS( d ), dimJ( d ), dimθ( d ) )
    offset = 0
    o = Vector{ Union{ A1{T}, A2{T}, A3{T}, A4{T} }}( undef, length( tups ) )
    for i ∈ eachindex( tups )
        t = tups[i]
        o[i] = unsafe_wrap( Array{T, length(t)}, p << offset, t  )
        offset += prod( t )
    end
    @assert 6 == length( MicroSpaceArraysNeeded( dimR( d.microdata ), dimS(d), dimJ( d ), dimθ( d ) ) )
    mic = GrumpsMicroSpace( o[1:6]..., true )
    mac = GrumpsMacroSpace( o[7:end]...,true )
    return GrumpsMarketSpace{T}( mic, mac, b )
end



function mustrecompute( s :: GrumpsMarketSpace{T} ) where {T<:Flt}
    return s.memblockindex ≠ NoMemblockIndex
end


struct GrumpsSpace{T<:Flt, S<:Semaphorian} <: Space{T} 
    marketspace     :: Vec{ GrumpsMarketSpace{T} }
    currentθ        :: Vec{ T }
    memsave         :: Bool
    semas           :: S

    # function GrumpsSpace( T2, M :: Int,  dθ :: Int, memsave :: Bool ) 
    #     @ensure T2<: Flt   "T must be a Float of some sort"
    #     @ensure M ≥ 0 && dθ ≥ 0   "negative length vectors are not permitted"

    #     g = GrumpsSpace{T2}{ Vector{ GrumpsMarketSpace{T2} }( undef, M ), fill( typemax( T2 ), dθ ),  memsave )
    #     g .marketspace .= nothing
    #     return g
    # end


end


mustrecompute( s :: GrumpsSpace{T,S} ) where {T<:Flt,S<:Semaphorian} = s.memsave




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

function GrumpsSpace( d :: GrumpsData{T}, ::Val{ false } ) where {T<:Flt}
    return GrumpsSpace{T,GrumpsNoSemaphores}( [ GrumpsMarketSpace{T}( 
            GrumpsMicroSpace( d.marketdata[m].microdata, false ), 
            GrumpsMacroSpace( d.marketdata[m].macrodata, false ),
            NoMemblockIndex
            ) for m ∈ 1:dimM( d ) ],
            fill( typemax( T ), dimθ( d ) ),
            false,
            GrumpsNoSemaphores()
             )
end


GrumpsSpace( d :: GrumpsData{T}, ::MemNoBlock{T} ) where {T<:Flt} = GrumpsSpace( d, Val( false ) )



function GrumpsSpace( d :: GrumpsData{T}, memblock :: MemBlock{T} ) where {T<:Flt}
    return GrumpsSpace{T,GrumpsSemaphores}( 
        [ GrumpsMarketSpace( d.marketdata[m], memblock, m ) for m ∈ 1:dimM( d ) ],
        fill( typemax( T ), dimθ( d ) ),
        true,
        GrumpsSemaphores( chunks( memblock ) )
    )
end


GrumpsSpace( e :: GrumpsEstimator, d :: GrumpsData{T}, o :: OptimizationOptions, memblock :: MemBlockian{T} ) where {T<:Flt} = GrumpsSpace( d, memblock )


# GrumpsSpace( e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions ) where {T<:Flt} = GrumpsSpace( d, Val( memsave( o ) ) )


