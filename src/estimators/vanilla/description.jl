name( ::Val{:vanilla} ) = "Grumps unpenalized MLE"


function Description( e :: Symbol, v ::Val{ :vanilla} )
    @ensure e == :vanilla "oops!"
    return EstimatorDescription( e, name( Val( :vanilla ) ), 
      [ "mle", "grumps mle", "maximum likelihood", "grumps maximum likelihood", "ml", "maxlik", "vanilla" ]
      )
end
