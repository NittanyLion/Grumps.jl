struct GrumpsGMMEstimator <: GrumpsGMM

    function GrumpsGMMEstimator( )
        new( )
    end
end


name( ::GrumpsGMMEstimator ) = name( Val( :gmm ) )

inisout( ::GrumpsGMMEstimator ) = false


Estimator( ::Val{ :gmm } ) = GrumpsGMMEstimator()


# Version( ::GrumpsGMMEstimator ) = GrumpsVersionGMM()

usesmicrodata( ::GrumpsGMMEstimator ) = true
usesmicromoments( ::GrumpsGMMEstimator ) = true
usespenalty( ::GrumpsGMMEstimator ) = true
seprocedure( ::GrumpsGMMEstimator ) = :notyetimplemented
IsCompatible( :: GrumpsGMMEstimator, :: MSMMicroIntegrator ) = true

function DetailedDescription( e :: GrumpsGMMEstimator )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is a ", EmColor, "GMM estimator. ", EstColor,
            "It augments macro moments with micro moments derived from the gradient of ", MathColor, " ℒ ᵐⁱᶜ( θ, δ )", EstColor, ". ",
            "Since BLP type models are fully parametric, maximum likelihood trumps GMM. ", 
            "Moreover, the routine implemented here is under construction. ",
            "It may always remain that way since it is inferior. ", Reset )
    return String( take!( io ) )
end
