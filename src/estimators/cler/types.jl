struct GrumpsCLEREstimator <: GrumpsPenalized
    function GrumpsCLEREstimator() 
        new()
    end
end


name( ::GrumpsCLEREstimator ) = name( Val( :cler ) )

inisout( ::GrumpsCLEREstimator ) = true
iopattern( ::GrumpsCLEREstimator ) = "111111"

Estimator( ::Val{ :cler } ) = GrumpsCLEREstimator()


const GrumpsCLEREstimatorInstance = GrumpsCLEREstimator()
