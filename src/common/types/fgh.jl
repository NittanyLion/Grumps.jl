


abstract type FGH{T<:Flt} end
abstract type MarketFGH{T<:Flt} <: FGH{T} end
abstract type SingleFGH{T<:Flt} <: FGH{T} end

struct GrumpsSingleFGH{T<:Flt} <: SingleFGH{T}
    F       :: Vec{T} 
    Gθ      :: Vec{T}
    Gδ      :: Vec{T}
    Hθθ     :: Mat{T}
    Hδθ     :: Mat{T}
    Hδδ     :: Mat{T}

    function GrumpsSingleFGH{T}( dθ :: Int, dδ :: Int ) where {T<:Flt}
        @ensure dθ ≥ 0 "dθ must be nonnegative"
        @ensure dδ ≥ 0 "dδ must be nonnegative"
        new{T}( zeros(T,1), zeros(T, dθ ), zeros(T, dδ), zeros(T, dθ,dθ), zeros(T,dδ, dθ), zeros(T, dδ, dδ ) )
    end
end

struct GrumpsMarketFGH{T<:Flt} <: MarketFGH{T}
    inside      :: GrumpsSingleFGH{T}
    outside     :: GrumpsSingleFGH{T}

    function GrumpsMarketFGH( T2 :: Type, e :: GrumpsEstimator, dθ :: Int, dδ :: Int, ::Val{false} )
        # constructor if inside and outside objective functions are different
        return new{T2}( GrumpsSingleFGH{T2}( dθ, dδ ), GrumpsSingleFGH{T2}( dθ, dδ ) )
    end
    function GrumpsMarketFGH( T2 :: Type, e :: GrumpsEstimator, dθ :: Int, dδ :: Int, ::Val{true} )
        # constructor if inside and outside objective functions are the same
        fgh = GrumpsSingleFGH{T2}( dθ, dδ )
        return new{T2}( fgh, fgh )
    end
end


struct GMMMarketFGH{T<:Flt} <: MarketFGH{T}
    inside      :: GrumpsSingleFGH{T}
    mom         :: Vec{ T }
    momdθ       :: Mat{ T }
    momdδ       :: Mat{ T }

    function GMMMarketFGH( T2 :: Type, e :: GrumpsEstimator, dθ :: Int, dδ :: Int, dmom :: Int )
        return new{T2}( 
            GrumpsSingleFGH{T2}( dθ, dδ),
            zeros( T2, dmom ),
            zeros( T2, dmom, dθ ),
            zeros( T2, dmom, dδ )
        )
    end
    
end



struct GrumpsFGH{T<:Flt} <: FGH{T}
    market      :: Vec{ GrumpsMarketFGH{T} }
end


struct GMMFGH{T<:Flt} <: FGH{T}
    market      :: Vec{ GMMMarketFGH{T} }
end

function FGH( e :: GrumpsMLE, d :: GrumpsData{T} ) where {T<:Flt}
    return GrumpsFGH{T}( [ GrumpsMarketFGH( T, e, dimθ( d ), dimδ( d.marketdata[m] ), Val( inisout( e ) ) ) for m ∈ 1:dimM( d ) ] )
end

function FGH( e :: GrumpsGMM, d :: GrumpsData{T} ) where {T<:Flt}
    return GMMFGH{T}( [ GMMMarketFGH( T, e, dimθ( d ), dimδ( d.marketdata[m] ), dimmom( d ) - dimβ( d ) + dimθz( d ) ) for m ∈ 1:dimM( d ) ] )
end



