struct GrumpsPLMEstimator <: GrumpsPLM
    function GrumpsPLMEstimator() 
        new()
    end
end


name( ::GrumpsPLMEstimator ) = name( Val( :plm ) )

inisout( ::GrumpsPLMEstimator ) = true

# @warn "*****************"
# @warn "gets read"
# @warn "****************"

# """
#     Estimator( ::Val{ :plm } ) 

# """
Estimator( ::Val{ :plm } ) = GrumpsPLMEstimator()


# Version( ::GrumpsVanillaEstimator ) = GrumpsVersionMLE()

inisout( ::GrumpsPLMEstimator ) = true

