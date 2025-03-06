struct GrumpsCLEER <: GrumpsPenalized
    function GrumpsCLEER() 
        new()
    end
end


name( ::GrumpsCLEER ) = name( Val( :cleer ) )

inisout( ::GrumpsCLEER ) = true
iopattern( ::GrumpsCLEER ) = "111111"

Estimator( ::Val{ :cleer } ) = GrumpsCLEER()


const GrumpsCLEERInstance = GrumpsCLEER()


function DetailedDescription( e :: GrumpsCLEER )
    io = IOBuffer()
    print( io, EstColor, "The estimator used here is the ", EmColor, "CLEER. ", EstColor,
            "It minimizes an objective function of the form ", MathColor,
            "Ω̂( θ, δ, β ) = ℒ ᵐⁱᶜ( θ, δ ) + ℒ ᵐᵃᶜ( θ, δ ) + Π( δ, β ) " , EstColor,
            "where the first two components are (minus) a micro likelihood and a macro likelihood ", 
            "and the last component is a GMM style objective function. ",
            "This is the full version of this estimator which takes longer to compute than the ",
            "asymptotically equivalent cheap version.  The main advantage of the full CLEER estimator ",
            "compared to the cheap version is that there is somewhat greater robustness to small shares.", Reset )
    return String( take!( io ) )
end
