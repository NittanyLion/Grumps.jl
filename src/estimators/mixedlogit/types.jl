struct GrumpsMixedLogitEstimator <: GrumpsMLE
    function GrumpsMixedLogitEstimator() 
        new()
    end
end

name( ::GrumpsMixedLogitEstimator ) = name( Val(:mixedlogit) )
inisout( ::GrumpsMixedLogitEstimator ) = true
iopattern( ::GrumpsMixedLogitEstimator ) = "100100"

Estimator( ::Val{ :mixedlogit } ) = GrumpsMixedLogitEstimator()

# Version( ::GrumpsMixedLogitEstimator ) = GrumpsVersionMLE()

usesmacrodata( ::GrumpsMixedLogitEstimator ) = false

function DetailedDescription( e :: GrumpsMixedLogitEstimator )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is the ", EmColor, "Mixed Logit Estimator. ", EstColor,
            "It minimizes an objective function of the form ", MathColor, "Ω̂( θ, δ ) = ℒ ᵐⁱᶜ( θ, δ ) ", EstColor,
            "with respect to θ and δ and then minimizes a GMM style objective function ", MathColor, " Π̂( δ̂, β ) ", EstColor, " with respect to β in a second ",
            "step.  If macro data (i.e. shares) are available then the CLER estimators (full and cheap) dominate the mixed logit estimator. ", 
            "The mixed logit estimator should only be considered if the micro sample is large, but even then the CLER estimators are at worst equivalent.", Reset )
    return String( take!( io ) )
end
