
name( ::Val{:mixedlogit} ) = "Mixed Logit"


function Description( e :: Symbol, v ::Val{ :mixedlogit } )
    @ensure e == :mixedlogit "oops!"
    return EstimatorDescription( e, name( Val( :mixedlogit ) ), 
      [ "mixed logit", "mixed", "random coefficients logit", "micro logit" ]
      )
end
