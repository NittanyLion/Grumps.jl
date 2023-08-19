struct GrumpsMDLEEstimator <: GrumpsMLE
    function GrumpsMDLEEstimator() 
        new()
    end
end


name( ::GrumpsMDLEEstimator ) = name( Val( :mdle ) )

inisout( ::GrumpsMDLEEstimator ) = true
iopattern( ::GrumpsMDLEEstimator ) = "110110"


Estimator( ::Val{ :mdle } ) = GrumpsMDLEEstimator()

const GrumpsMDLEEstimatorInstance = GrumpsMDLEEstimator()

function DetailedDescription( e :: GrumpsMDLEEstimator )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is the ", EmColor, "Mixed Data Likelihood Estimator. ", EstColor,
            "It minimizes an objective function of the form ", MathColor, "Ω̂( θ, δ ) = ℒ ᵐⁱᶜ( θ, δ ) + ℒ ᵐᵃᶜ( θ, δ ) ", EstColor,
            "with respect to θ and δ and then minimizes a GMM style objective function ", MathColor, " Π̂( δ̂, β ) ", EstColor, " with respect to β in a second ",
            "step.  Unlike the CLER estimator (both the full and cheap version), the MDLE is not fully robust. ", 
            "Moreover, in some circumstances it is also less efficient, even converge at a slower rate. ", Reset )
    return String( take!( io ) )
end
