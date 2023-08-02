name( ::Val{:mdle} ) = "Mixed data likelihood estimator"


function Description( e :: Symbol, v ::Val{ :mdle} )
    @ensure e == :mdle "oops!"
    return EstimatorDescription( e, name( Val( :mdle ) ), 
      [ "mle", "grumps mle", "maximum likelihood", "grumps maximum likelihood", "ml", "maxlik", "vanilla", "grumps unpenalized", "mdle" ]
      )
end
