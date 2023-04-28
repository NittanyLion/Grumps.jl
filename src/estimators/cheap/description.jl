name( ::Val{:cheap} ) = "Grumps Penalized MLE (cheap version)"


function Description( e :: Symbol, v ::Val{ :cheap } )
    @ensure e == :cheap "oops!"
    return EstimatorDescription( e, name( Val( :cheap ) ), 
      [ "cheap" ]
      )
end
