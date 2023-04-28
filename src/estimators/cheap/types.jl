struct GrumpsCheapEstimator <: GrumpsMLE
    function GrumpsCheapEstimator() 
        new()
    end
end


name( ::GrumpsCheapEstimator ) = name( Val( :cheap ) )

inisout( ::GrumpsCheapEstimator ) = true
usespenalty( ::GrumpsCheapEstimator ) = true
iopattern( ::GrumpsCheapEstimator ) = "110111"

Estimator( ::Val{ :cheap } ) = GrumpsCheapEstimator()


const GrumpsCheapEstimatorInstance = GrumpsCheapEstimator()

