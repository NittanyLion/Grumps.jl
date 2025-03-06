struct GrumpsDevelopmentEstimator <: GrumpsDevelopment
    function GrumpsDevelopmentEstimator() 
        new()
    end
end


name( ::GrumpsDevelopmentEstimator ) = name( Val( :development ) )

inisout( ::GrumpsDevelopmentEstimator ) = true
iopattern( ::GrumpsDevelopmentEstimator ) = "111111"

Estimator( ::Val{ :development } ) = GrumpsDevelopmentEstimator()


const GrumpsDevelopmentEstimatorInstance = GrumpsDevelopmentEstimator()


function DetailedDescription( e :: GrumpsDevelopmentEstimator )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is the ", EmColor, "Development estimator. ", EstColor,
            "It minimizes an objective function of the form ", MathColor,
            "Ω̂( θ, δ, β ) = ℒ ᵐⁱᶜ( θ, δ ) + ℒ ᵐᵃᶜ( θ, δ ) + Π( δ, β ) " , EstColor,
            "where the first two components are (minus) a micro likelihood and a macro likelihood ", 
            "and the last component is a GMM style objective function. ",
            "This is the full version of this estimator which takes longer to compute than the ",
            "asymptotically equivalent cheap version.  The main advantage of the full Development estimator ",
            "compared to the cheap version is that there is somewhat greater robustness to small shares.", Reset )
    return String( take!( io ) )
end
