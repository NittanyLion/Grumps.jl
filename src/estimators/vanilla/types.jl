struct GrumpsVanillaEstimator <: GrumpsMLE
    function GrumpsVanillaEstimator() 
        new()
    end
end


name( ::GrumpsVanillaEstimator ) = name( Val( :vanilla ) )

inisout( ::GrumpsVanillaEstimator ) = true
iopattern( ::GrumpsVanillaEstimator ) = "110110"


Estimator( ::Val{ :vanilla } ) = GrumpsVanillaEstimator()

const GrumpsVanillaEstimatorInstance = GrumpsVanillaEstimator()

