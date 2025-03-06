name( ::Val{:cleer} ) = "Conformant Likelihood with Exogeneity Restrictions"





function Description( e :: Symbol, v ::Val{ :cleer } )
    @ensure e == :cleer "oops!"
    return EstimatorDescription( e, name( Val( :cleer ) ), 
      [ "grumps", "pmle", "grumps penalized mle", "penalized likelihood", "grumps penalized maximum likelihood", "pml", "penmaxlik", "grumps pml", "cleer", "full cleer" ]
      )
end
