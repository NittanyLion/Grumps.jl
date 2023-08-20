# The functions below return dimensions info for Grumps objects


dimθz( d :: GrumpsMicroDataHog )    = size( d.Z, 3 )
dimθν( d :: GrumpsMicroDataHog )    = size( d.X, 3 )
dimθ( d :: GrumpsMicroDataHog )     = dimθz( d ) + dimθν( d )
dimδ( d :: GrumpsMicroDataHog )     = size( d.Z, 2 ) - 1
dimδm( d :: GrumpsMicroDataHog )    = dimδ( d )
dimS( d :: GrumpsMicroDataHog )     = size( d.Z, 1 )
dimR( d :: GrumpsMicroDataHog )     = size( d.X, 1 )
dimmom( d :: GrumpsMicroDataHog )   = size( d.ℳ, 3 )

dimθz( d :: MSMMicroDataHog )    = size( d.Z, 3 )
dimθν( d :: MSMMicroDataHog )    = size( d.X, 4 )
dimθ( d :: MSMMicroDataHog )     = dimθz( d ) + dimθν( d )
dimδ( d :: MSMMicroDataHog )     = size( d.Z, 2 ) - 1
dimδm( d :: MSMMicroDataHog )    = dimδ( d )
dimS( d :: MSMMicroDataHog )     = size( d.Z, 1 )
dimR( d :: MSMMicroDataHog )     = size( d.X, 1 )
dimmom( d :: MSMMicroDataHog )   = size( d.ℳ, 3 )

dimθz( d :: GrumpsMicroDataAnt )    = size( d.Z, 3 )
dimθν( d :: GrumpsMicroDataAnt )    = size( d.𝒳, 2 )
dimθ( d :: GrumpsMicroDataAnt )     = dimθz( d ) + dimθν( d )
dimδ( d :: GrumpsMicroDataAnt )     = size( d.Z, 2 ) - 1
dimδm( d :: GrumpsMicroDataAnt )    = dimδ( d )
dimS( d :: GrumpsMicroDataAnt )     = size( d.Z, 1 )
dimR( d :: GrumpsMicroDataAnt )     = size( d.𝒳, 1 )
dimmom( d :: GrumpsMicroDataAnt )   = size( d.ℳ, 3 )

dimθz( d :: GrumpsMicroNoData )    = 0
dimθν( d :: GrumpsMicroNoData )    = 0
dimθ( d :: GrumpsMicroNoData )     = 0
dimδ( d :: GrumpsMicroNoData )     = 0
dimδm( d :: GrumpsMicroNoData )    = 0
dimS( d :: GrumpsMicroNoData )     = 0
dimR( d :: GrumpsMicroNoData )     = 0

dimθ( d :: GrumpsMacroNoData )     = 0
dimδ( d :: GrumpsMacroNoData )     = 0
dimδm( d :: GrumpsMacroNoData )    = 0
dimR( d :: GrumpsMacroNoData )     = 0
dimN( d :: GrumpsMacroNoData )     = 0


dimθ( d :: GrumpsMacroDataAnt )     = size( d.𝒳, 2 )
dimδ( d :: GrumpsMacroDataAnt )     = size( d.𝒳, 1 ) - 1
dimδm( d :: GrumpsMacroDataAnt )    = dimδ( d )
dimR( d :: GrumpsMacroDataAnt )     = size( d.𝒟, 1 )
dimN( d :: GrumpsMacroDataAnt )     = d.N


dimθ( d :: GrumpsMacroDataHog )     = size( d.A, 3 )
dimδ( d :: GrumpsMacroDataHog )     = size( d.A, 2 ) - 1
dimδm( d :: GrumpsMacroDataHog )    = dimδ( d )
dimR( d :: GrumpsMacroDataHog )     = size( d.A, 1 )
dimN( d :: GrumpsMacroDataHog )     = d.N


dimθz( d :: GrumpsMarketData )      = dimθz( d.microdata )
dimθν( d :: GrumpsMarketData )      = dimθν( d.microdata )
dimθ( d :: GrumpsMarketData )       = isempty( d.microdata ) ? dimθ( d.macrodata ) : dimθ( d.microdata )
dimδ( d :: GrumpsMarketData )       = isempty( d.microdata ) ? dimδ( d.macrodata ) : dimδ( d.microdata )
dimδm( d :: GrumpsMarketData )      = dimδ( d )
dimS( d :: GrumpsMarketData )       = dimS( d.microdata )
dimN( d :: GrumpsMarketData )       = dimN( d.macrodata )
dimmom( d :: GrumpsMarketData )     = dimmom( d.microdata )

dimβ( d :: GrumpsPLMData )   = size( d.𝒳, 2 )
dimδ( d :: GrumpsPLMData )   = size( d.𝒳, 1 )
dimmom( d :: GrumpsPLMData ) = d.dmom

dimJ( d ) = dimδm( d ) + 1



dimθ( d :: Dimensions )     = d.θ
dimθz( d :: Dimensions )    = d.θz
dimθν( d :: Dimensions )    = d.θν
dimδ( d :: Dimensions )     = d.δ
dimδm( d :: Dimensions )    = d.δm
dimβ( d :: Dimensions )     = d.β
dimM( d :: Dimensions )     = length( d.δm )
dimmom( d :: Dimensions )   = d.dmom

dimθ( d :: GrumpsData )     = dimθ( d.dims )
dimθz( d :: GrumpsData )    = dimθz( d.dims )
dimθν( d :: GrumpsData )    = dimθν( d.dims )
dimδ( d :: GrumpsData )     = dimδ( d.dims )
dimδm( d :: GrumpsData )    = dimδm( d.dims )
dimβ( d :: GrumpsData )     = dimβ( d.dims )
dimM( d :: GrumpsData )     = dimM( d.dims )
dimmom( d :: GrumpsData )   = dimmom( d.dims )
dimS( d :: GrumpsData )     = dimS.( d.marketdata )
dimJ( d :: GrumpsData )     = dimJ.( d.marketdata )
dimN( d :: GrumpsData )     = dimN.( d.marketdata )
dimRmic( d :: GrumpsData )     = dimR.( [ d.marketdata[m].microdata for m ∈ eachindex( d.marketdata ) ] )
dimRmac( d :: GrumpsData )     = dimR.( [ d.marketdata[m].macrodata for m ∈ eachindex( d.marketdata ) ] )

function dimsθ( d :: GrumpsData ) 
    return dimθ( d ), dimθz( d ), dimθν( d )
end


"""
    RSJ( d :: GrumpsMicroData )

Returns ranges for weights, consumers, products, δ parameters, and θ parameters
"""
function RSJ( d :: GrumpsMicroData )
    return 1:dimR( d ), 1:dimS( d ), 1:dimJ( d ), 1:dimδ( d ), 1:dimθ( d )
end


RSJ( d :: GrumpsMarketData ) = RSJ( d.microdata )


function RJ( d :: GrumpsMacroData )
    return 1:dimR( d ), 1:dimJ( d ), 1:dimδ( d ), 1:dimθ( d )
end
