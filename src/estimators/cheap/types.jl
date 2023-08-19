struct GrumpsCheapEstimator <: GrumpsMLE
    function GrumpsCheapEstimator() 
        new()
    end
end


name( ::GrumpsCheapEstimator ) = name( Val( :cheap ) )

inisout( ::GrumpsCheapEstimator ) = true
usespenalty( ::GrumpsCheapEstimator ) = true
iopattern( ::GrumpsCheapEstimator ) = "110111"

Estimator( ::Val{ :cheap } ) = GrumpsCheapEstimator()


const GrumpsCheapEstimatorInstance = GrumpsCheapEstimator()


function DetailedDescription( e :: GrumpsCheapEstimator )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is the ", EmColor, "cheap version of the Conformant Likelihood with Exogeneity Restrictions estimator. ", EstColor,
            "It minimizes an objective function of the form ", MathColor, "Ω̂( θ, δ, β ) = ℒ ᵐⁱᶜ( θ, δ ) + ℒ ᵐᵃᶜ( θ, δ ) ", EstColor,
            "with respect to δ in the inner loop and then minimizes an objective function of the form ", MathColor,
            "Ω̂( θ, δ, β ) = ℒ ᵐⁱᶜ( θ, δ ) + ℒ ᵐᵃᶜ( θ, δ ) + Π( δ, β )", EstColor, " in the outer loop. ",
            "Here, the first two components are (minus) a micro likelihood and a macro likelihood ", 
            "and the last component is a GMM style objective function. ",
            "The cheap version computes faster and has the same asymptotic distribution as the full CLER estimator. ",
            "The only difference is that the full CLER estimator has somewhat greater robustness to small shares.", Reset )
    return String( take!( io ) )
end

