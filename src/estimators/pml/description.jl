name( ::Val{:pml} ) = "Grumps Penalized MLE"


function Description( e :: Symbol, v ::Val{ :pml } )
    @ensure e == :pml "oops!"
    return EstimatorDescription( e, name( Val( :pml ) ), 
      [ "grumps", "pmle", "grumps penalized mle", "penalized likelihood", "grumps penalized maximum likelihood", "pml", "penmaxlik", "grumps pml" ]
      )
end