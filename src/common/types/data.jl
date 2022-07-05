

abstract type Data{T<:Flt} end
abstract type MicroData{T} <: Data{T} end
abstract type MacroData{T} <: Data{T} end
abstract type MarketData{T} <: Data{T} end
abstract type PLMData{T} <: Data{T} end
abstract type AllData{T} <: Data{T} end
abstract type GrumpsMacroData{T} <: MacroData{T} end
abstract type GrumpsMicroData{T} <: MicroData{T} end
# abstract type GrumpsPLMData{T} <: PLMData{T} end 


struct GrumpsMicroDataHog{T<:Flt} <: GrumpsMicroData{T}
    name    :: String
    Z       ::  A3{T}
    X       ::  A3{T}
    y       ::  Vec{Int}
    Y       ::  Mat{Bool}
    w       ::  Vec{T}
    ℳ       ::  A3{T}

    function GrumpsMicroDataHog{T2}( name :: String, Z :: A3{T2}, X :: A3{T2}, y :: Vec{Int}, Y :: Matrix{Bool}, w :: Vec{T2}, ℳ :: A3{T2} ) where {T2<:Flt}
        # sanity checking
        S, J, dθz = size( Z )
        R, dθν = size( X, 1 ), size( X, 3 )
        @info "micro market size $name = $R $S $J $dθz $dθν"
        @ensure size( X,2 ) == J  "number of products mismatch X"
        @ensure size( Y, 2 ) == J  "number of products mismatch Y"
        @ensure length( y ) == S "number of consumers mismatch y"
        @ensure size( Y, 1 ) == S "number of consumers mismatch Y"
        @ensure length( w ) == R "number of nodes mismatch w"
        new{T2}( name, Z, X, y, Y, w, ℳ )
    end
end

struct GrumpsMicroDataAnt{T<:Flt} <: GrumpsMicroData{T}
    name    ::  String
    Z       ::  A3{T}
    𝒳       ::  Mat{T}
    𝒟       ::  Mat{T}
    y       ::  Vec{Int}
    Y       ::  Mat{Bool}
    w       ::  Vec{T}
    ℳ       ::  A3{T}   

    function GrumpsMicroDataAnt{T2}( name :: String, Z :: A3{T2}, 𝒳 :: Mat{T2}, 𝒟 :: Mat{T2}, y :: Vec{Int}, Y :: Matrix{Bool}, w :: Vec{T2}, ℳ :: A3{T2}  ) where {T2<:Flt}
        # sanity checking
        S, J, dθz = size( Z )
        R, dθν = size( 𝒟 )
        @ensure J == size( 𝒳, 1 )  "number of products mismatch 𝒳 in market $name"
        @ensure size( Y, 2 ) == J  "number of products mismatch Y in market $name"
        @ensure dθν == size( 𝒳, 2 ) "number of random coefficients mismatch 𝒳 in market $name"
        @ensure length( y ) == S "number of consumers mismatch y in market $name"
        @ensure size( Y, 1 ) == S "number of consumers mismatch Y in market $name"
        @ensure length( w ) == R "number of nodes mismatch w in market $name"
        new{T2}( name, Z, 𝒳, 𝒟, y, Y, w, ℳ )
    end
end


struct GrumpsMicroNoData{T<:Flt} <: GrumpsMicroData{T}
    name    :: String
end


struct GrumpsMacroDataAnt{T<:Flt} <: GrumpsMacroData{T}
    name    :: String
    𝒳       ::  Mat{T}      # product level regressors
    𝒟       ::  Mat{T}      # random draws
    s       ::  Vec{T}      # shares
    N       ::  T
    w       ::  Vec{T}

    function GrumpsMacroDataAnt{T2}( name :: String, 𝒳 :: Mat{T2}, 𝒟 :: Mat{T2}, s :: Vec{T2}, N :: T2, w :: Vec{T2} ) where {T2<:Flt}
        # sanity checking
        J, dθ = size( 𝒳 )
        R = size( 𝒟, 1 )
        @info "macro market size $name = $R $J $dθ"
        @ensure size( 𝒟, 2 ) == dθ  "number of coefficients mismatch 𝒟 in market $name"
        @ensure length( s ) == J  "number of products mismatch s in market $name"
        @ensure length( w ) == R "number of nodes mismatch w in market $name"
        @ensure minimum( s ) ≥ zero( T2 )  "shares should be nonnegative in market $name"
        @ensure N ≥ zero( T2 ) "market size should be nonnegative in market $name"
        new{T2}( name, 𝒳, 𝒟, s, N, w )
    end
end

struct GrumpsMacroDataHog{T<:Flt} <: GrumpsMacroData{T}
    name    :: String
    A       :: A3{T}        # interactions
    s       :: Vec{T}       # shares
    N       :: T
    w       :: Vec{T}

    function GrumpsMacroDataHog{T2}( name :: String, A :: A3{T2}, s :: Vec{T2}, N :: T2, w :: Vec{T2} ) where {T2<:Flt}
        # sanity checking
        R, J, dθ = size( A )
        @ensure length( s ) == J  "number of products mismatch s in market $name"
        @ensure length( w ) == R "number of nodes mismatch w in market $name"
        @ensure minimum( s ) ≥ zero( T2 )  "shares should be nonnegative in market $name"
        @ensure N ≥ zero( T2 ) "market size should be nonnegative in market $name"
        new{T2}( name, A, s, N, w )
    end
end

struct GrumpsMacroNoData{T<:Flt} <: GrumpsMacroData{T}
    name    :: String
end

struct GrumpsPLMData{T<:Flt} <: PLMData{T}
    𝒳       :: Mat{T}       # X
    𝒳̂       :: Mat{T}       # P_Z X
    names   :: Vec{ String }
    dmom    :: Int
    𝒦       :: Mat{T}
    σ2      :: T

    function GrumpsPLMData( 𝒳 :: Mat{T2}, 𝒳̂ :: Mat{T2}, names :: Vec{String}, dmom :: Int, 𝒦 :: Mat{T2}, σ2 :: T2 = 1.0 ) where {T2<:Flt}
        dδ, dβ  = size( 𝒳 )
        @ensure dδ == size( 𝒳̂, 1 )  "mismatch in first dimension"
        @ensure dβ == size( 𝒳̂, 2 )  "mismatch in second dimension"
        @ensure length( names ) == dβ  "incorrect number of names"
        @ensure dmom ≥ dβ "underidentification in product level moments"
        @ensure size( 𝒦, 1 ) == dδ  "𝒦 must have the same number of rows as 𝒳"
        @ensure σ2 > 0.0        "error variance must be positive"
        new{T2}( 𝒳, 𝒳̂, names, dmom, 𝒦, σ2    )
    end
end


# struct GrumpsPLMDataPenalty{T<:Flt} <: GrumpsPLMData{T}

# end

# struct GrumpsPLMData{T<:Flt} <: PLMData{T}
#     𝒳   :: Matrix{T}    # regressors
#     𝒵   :: Matrix{T}    # instruments
#     𝒦   :: Matrix{T}    # projection
#     σ2  :: T            # second stage error variance
# end


struct VariableNames
    θnames  ::  Vec{ String }
    βnames  ::  Vec{ String }
    δnames  ::  Vec{ String }
end


struct Dimensions
    θ      :: Int
    θz     :: Int
    θν     :: Int
    β      :: Int
    δ      :: Int
    δm     :: Vec{Int}
    dmom   :: Int

    function Dimensions( dθ :: Int, dθz :: Int, dθν :: Int, dβ :: Int, dδm :: Vec{Int}, dmom :: Int )
        return new( dθ, dθz, dθν, dβ, sum( dδm ), dδm, dmom )
    end
end

struct GrumpsMarketData{T<:Flt} <: MarketData{T}
    microdata       :: GrumpsMicroData{T}
    macrodata       :: GrumpsMacroData{T} 
end

struct GrumpsData{T<:Flt} <: AllData{T}
    marketdata      :: Vec{ GrumpsMarketData{T} }
    plmdata         :: GrumpsPLMData{T}
    variablenames   :: VariableNames
    balance         :: Vec{ GrumpsNormalization{T} }
    dims            :: Dimensions

    function GrumpsData{T2}( md :: Vec{ GrumpsMicroData{T2} }, Md :: Vec{ GrumpsMacroData{T2} }, plm :: GrumpsPLMData{T2}, varnames :: VariableNames, bal :: Vec{GrumpsNormalization{T2}}, dims :: Dimensions ) where {T2<:Flt}
        # just doing some sanity checking
        @ensure length( md ) == length( Md )  "number of micro and macro markets does not match"
        @warn "need to put in more sanity checks here"
        for m ∈ eachindex( md )
            if !( typeof( md[m] ) <: GrumpsMicroNoData )
                @ensure dimθ( md[m] ) == dims.θ "dimension θ does not match"
                @ensure dimθz( md[m] ) == dims.θz "dimension θz does not match"
                @ensure dimθν( md[m] ) == dims.θν "dimension θν does not match"
                @ensure dimδm( md[m] ) == dims.δm[m] "dimension δm does not match"
            end
            if !( typeof( Md[m] ) <: GrumpsMacroNoData )
                @ensure dimθ( Md[m] ) == dims.θ "dimension θ does not match"
                @ensure dimδm( Md[m] ) == dims.δm[m] "dimension δm does not match"
            end
        end
        @ensure dimβ( plm ) == dims.β "dimension β does not match"
        marketdata = [ GrumpsMarketData{T2}( md[m], Md[m] ) for m ∈ eachindex( md ) ]
        new{T2}( marketdata, plm, varnames, bal, dims )
    end
end

isempty( ::Data ) = false
isempty( ::GrumpsMicroNoData ) = true
isempty( ::GrumpsMacroNoData ) = true



