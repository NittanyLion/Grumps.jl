struct GrumpsVanillaEstimator <: GrumpsMLE
    function GrumpsVanillaEstimator() 
        new()
    end
end


name( ::GrumpsVanillaEstimator ) = name( Val( :vanilla ) )

inisout( ::GrumpsVanillaEstimator ) = true

Estimator( ::Val{ :vanilla } ) = GrumpsVanillaEstimator()


Version( ::GrumpsVanillaEstimator ) = GrumpsVersionMLE()