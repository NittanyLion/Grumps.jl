struct GrumpsMixedLogitEstimator <: GrumpsMLE
    function GrumpsMixedLogitEstimator() 
        new()
    end
end

name( ::GrumpsMixedLogitEstimator ) = name( Val(:mixedlogit) )
inisout( ::GrumpsMixedLogitEstimator ) = true

Estimator( ::Val{ :mixedlogit } ) = GrumpsMixedLogitEstimator()

Version( ::GrumpsMixedLogitEstimator ) = GrumpsVersionMLE()
