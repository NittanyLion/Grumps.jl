name( ::Val{:gmm} ) = "GMM with smart moments"


function Description( e :: Symbol, v ::Val{ :gmm } )
    @ensure e == :gmm "oops!"
    return EstimatorDescription( e, name( Val( :gmm ) ), 
      [ "gmm", "generalized method of moments", "blp04", "berry et al 2004", "micro blp" ]
      )
end
