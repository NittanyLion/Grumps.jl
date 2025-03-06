struct GrumpsCLEREstimator <: GrumpsPenalized
    function GrumpsCLEREstimator() 
        new()
    end
end


name( ::GrumpsCLEREstimator ) = name( Val( :cler ) )

inisout( ::GrumpsCLEREstimator ) = true
iopattern( ::GrumpsCLEREstimator ) = "111111"

Estimator( ::Val{ :cler } ) = GrumpsCLEREstimator()


const GrumpsCLEREstimatorInstance = GrumpsCLEREstimator()


function DetailedDescription( e :: GrumpsCLEREstimator )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is the ", EmColor, "Conformant Likelihood with Exogeneity Restrictions estimator. ", EstColor,
            "It minimizes an objective function of the form ", MathColor,
            "Ω̂( θ, δ, β ) = ℒ ᵐⁱᶜ( θ, δ ) + ℒ ᵐᵃᶜ( θ, δ ) + Π( δ, β ) " , EstColor,
            "where the first two components are (minus) a micro likelihood and a macro likelihood ", 
            "and the last component is a GMM style objective function. ",
            "This is the full version of this estimator which takes longer to compute than the ",
            "asymptotically equivalent cheap version.  The main advantage of the full CLER estimator ",
            "compared to the cheap version is that there is somewhat greater robustness to small shares.", Reset )
    return String( take!( io ) )
end
