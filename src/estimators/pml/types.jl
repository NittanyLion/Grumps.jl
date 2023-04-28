struct GrumpsPMLEstimator <: GrumpsPenalized
    function GrumpsPMLEstimator() 
        new()
    end
end


name( ::GrumpsPMLEstimator ) = name( Val( :pml ) )

inisout( ::GrumpsPMLEstimator ) = true
iopattern( ::GrumpsPMLEstimator ) = "111111"

Estimator( ::Val{ :pml } ) = GrumpsPMLEstimator()


const GrumpsPMLEstimatorInstance = GrumpsPMLEstimator()
