name( ::Val{:development} ) = "Development version"


function Description( e :: Symbol, v ::Val{ :development } )
    @ensure e == :development "oops!"
    return EstimatorDescription( e, name( Val( :development ) ), 
      [ "development" ]
      )
end



