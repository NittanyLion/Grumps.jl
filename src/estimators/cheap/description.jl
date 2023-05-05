name( ::Val{:cheap} ) = "Conformant Likelihood with Exogeneity Restrictions (cheap version)"


function Description( e :: Symbol, v ::Val{ :cheap } )
    @ensure e == :cheap "oops!"
    return EstimatorDescription( e, name( Val( :cheap ) ), 
      [ "cheap", "cheap cler" ]
      )
end
