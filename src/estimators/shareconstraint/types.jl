struct GrumpsShareConstraintEstimator <: GrumpsMLE
    function GrumpsShareConstraintEstimator() 
        new()
    end
end


name( ::GrumpsShareConstraintEstimator ) = name( Val( :shareconstraint ) )

inisout( ::GrumpsShareConstraintEstimator ) = false
iopattern( ::GrumpsShareConstraintEstimator ) = "010110"

Estimator( ::Val{ :shareconstraint } ) = GrumpsShareConstraintEstimator()

seprocedure( ::GrumpsShareConstraintEstimator ) = :notyetimplemented


function DetailedDescription( e :: GrumpsShareConstraintEstimator )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is the ", EmColor, "Share Constraint Estimator. ", EstColor,
            "It minimizes an objective function of the form ", MathColor, "Ω̂( θ, δ ) = ℒ ᵐᵃᶜ( θ, δ ) ", EstColor,
            "with respect to δ in an inner loop, then minimizes ", MathColor, "ℒ ᵐⁱᶜ( θ, δ̂ )", EstColor,
            " with respect to θ in an outer loop and finally minimizes a GMM style objective function ", MathColor, " Π̂( δ̂, β ) ", 
            EstColor, " with respect to β in a final step.  This estimator is dominated by several other choices. ", Reset )
    return String( take!( io ) )
end