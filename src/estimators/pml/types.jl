struct GrumpsPMLEstimator <: GrumpsPenalized
    function GrumpsPMLEstimator() 
        new()
    end
end


name( ::GrumpsPMLEstimator ) = name( Val( :pml ) )

inisout( ::GrumpsPMLEstimator ) = true

Estimator( ::Val{ :pml } ) = GrumpsPMLEstimator()



