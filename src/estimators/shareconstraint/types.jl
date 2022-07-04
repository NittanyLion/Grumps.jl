struct GrumpsShareConstraintEstimator <: GrumpsMLE
    function GrumpsShareConstraintEstimator() 
        new()
    end
end


name( ::GrumpsShareConstraintEstimator ) = name( Val( :shareconstraint ) )

inisout( ::GrumpsShareConstraintEstimator ) = false

Estimator( ::Val{ :shareconstraint } ) = GrumpsShareConstraintEstimator()

seprocedure( ::GrumpsShareConstraintEstimator ) = :notyetimplemented
