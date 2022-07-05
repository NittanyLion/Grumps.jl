struct GrumpsGMMEstimator <: GrumpsGMM

    function GrumpsGMMEstimator( )
        new( )
    end
end


name( ::GrumpsGMMEstimator ) = name( Val( :gmm ) )

inisout( ::GrumpsGMMEstimator ) = false


Estimator( ::Val{ :gmm } ) = GrumpsGMMEstimator()


# Version( ::GrumpsGMMEstimator ) = GrumpsVersionGMM()

usesmicrodata( ::GrumpsGMMEstimator ) = true
usesmicromoments( ::GrumpsGMMEstimator ) = true
usespenalty( ::GrumpsGMMEstimator ) = true

seprocedure( ::GrumpsGMMEstimator ) = :notyetimplemented
