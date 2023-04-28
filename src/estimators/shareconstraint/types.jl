struct GrumpsShareConstraintEstimator <: GrumpsMLE
    function GrumpsShareConstraintEstimator() 
        new()
    end
end


name( ::GrumpsShareConstraintEstimator ) = name( Val( :shareconstraint ) )

inisout( ::GrumpsShareConstraintEstimator ) = false
iopattern( ::GrumpsShareConstraintEstimator ) = "010110"

Estimator( ::Val{ :shareconstraint } ) = GrumpsShareConstraintEstimator()

seprocedure( ::GrumpsShareConstraintEstimator ) = :notyetimplemented
