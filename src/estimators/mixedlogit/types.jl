struct GrumpsMixedLogitEstimator <: GrumpsMLE
    function GrumpsMixedLogitEstimator() 
        new()
    end
end

name( ::GrumpsMixedLogitEstimator ) = name( Val(:mixedlogit) )
inisout( ::GrumpsMixedLogitEstimator ) = true
iopattern( ::GrumpsMixedLogitEstimator ) = "100100"

Estimator( ::Val{ :mixedlogit } ) = GrumpsMixedLogitEstimator()

# Version( ::GrumpsMixedLogitEstimator ) = GrumpsVersionMLE()

usesmacrodata( ::GrumpsMixedLogitEstimator ) = false

