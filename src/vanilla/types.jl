struct GrumpsVanillaEstimator <: GrumpsMLE
    function GrumpsVanillaEstimator() 
        new()
    end
end


name( ::GrumpsVanillaEstimator ) = name( Val( :vanilla ) )

inisout( ::GrumpsVanillaEstimator ) = true

# @warn "*****************"
# @warn "gets read"
# @warn "****************"

# """
#     Estimator( ::Val{ :vanilla } ) 

# """
Estimator( ::Val{ :vanilla } ) = GrumpsVanillaEstimator()


# Version( ::GrumpsVanillaEstimator ) = GrumpsVersionMLE()

