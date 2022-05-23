name( ::Val{:plm} ) = "Grumps Penalized MLE"


function Description( e :: Symbol, v ::Val{ :plm } )
    @ensure e == :plm "oops!"
    return EstimatorDescription( e, name( Val( :plm ) ), 
      [ "pmle", "grumps penalized mle", "penalized likelihood", "grumps penalized maximum likelihood", "pml", "penmaxlik" ]
      )
end
