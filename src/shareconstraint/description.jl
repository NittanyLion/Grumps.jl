name( ::Val{:shareconstraint} ) = "Share Constraint MLE"


function Description( e :: Symbol, v ::Val{ :shareconstraint } )
    @ensure e == :shareconstraint "oops!"
    return EstimatorDescription( e, name( Val( :shareconstraint ) ), 
      [ "sc", "shareconstraint", "mle with share constraint", "share constraint" ]
      )
end
