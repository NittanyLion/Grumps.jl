struct GrumpsMDLEEstimator <: GrumpsMLE
    function GrumpsMDLEEstimator() 
        new()
    end
end


name( ::GrumpsMDLEEstimator ) = name( Val( :mdle ) )

inisout( ::GrumpsMDLEEstimator ) = true
iopattern( ::GrumpsMDLEEstimator ) = "110110"


Estimator( ::Val{ :mdle } ) = GrumpsMDLEEstimator()

const GrumpsMDLEEstimatorInstance = GrumpsMDLEEstimator()

