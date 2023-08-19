name( ::Val{:cler} ) = "Conformant Likelihood with Exogeneity Restrictions"


function Description( e :: Symbol, v ::Val{ :cler } )
    @ensure e == :cler "oops!"
    return EstimatorDescription( e, name( Val( :cler ) ), 
      [ "grumps", "pmle", "grumps penalized mle", "penalized likelihood", "grumps penalized maximum likelihood", "pml", "penmaxlik", "grumps pml", "cler", "full cler" ]
      )
end



