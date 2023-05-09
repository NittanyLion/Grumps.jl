



"""
    Estimator( s :: String )

Creates and returns a GrumpsEstimator type.  Grumps is reasonably good at figuring out what it is that you want, so e.g.
*Estimator( "maximum likelihood" )* gives you the unpenalized Grumps maximum likelihood estimator.

The estimators currently programmed include:
* the full Grumps estimator
* a cheaper alternative that has the same limit distribution
* Grumps-style maximum likelihood, i.e Grumps without penalty
* ditto, but imposing share constraints
* GMM estimator that uses both micro and macro moments and uses quadrature instead of Monte Carlo draws in the micro moments.  The micro moments are `smart' in that they condition on \$z_{im}\$ instead of integrating it out.
* a mixed logit estimator
"""
function Estimator( s :: String )
    s = lowercase( s )
    val = Vector{Float64}( undef, length(estdesc) )
    for e ∈ eachindex( estdesc )
        fn = findnearest( s, estdesc[e].descriptions, Levenshtein() )
        val[e] = fn[1] == nothing ? typemax(F64) : Levenshtein()( s, fn[1] )
    end
    @ensure !all( val .== typemax( F64 ) ) "cannot find desired estimator"
    winner = argmin( val )
    @info "identified $(estdesc[winner].name) as the estimator intended"
    return Estimator( Val( estdesc[winner].symbol ) )
end


"""
    Estimator( s :: Symbol )

Creates and returns a GrumpsEstimator type.

This is one method of specifying the estimator used.  However, it is unforgiving in that the exact symbol used internally must be passed, so
the *Estimator( s :: String )* method is usually a better choice.

Possible choices include:

*:cler* the full Grumps maximum likelihood estimator  

*:cheap* an alternative with the same limit distribution that is faster to compute

*:mdle* the minimum distance likelihood estimator

*:shareconstraint* the MDLE estimator with share constraints

*:gmm* GMM estimator that uses both micro and macro moments

*:mixedlogit* mixed logit maximum likelihood estimator
"""
Estimator( s :: Symbol ) = Estimator( Val( s ) )



function Estimators( ::Val{ false } )
    printstyledln( "Available estimators:\n"; bold = true )
    for e ∈ eachindex( estdesc )
        printstyled( @sprintf( "%30s", estdesc[e].name ); color = :red )
        printstyledln( "  :", estdesc[e].symbol; color = :blue)
    end
    return nothing
end


function Estimators( ::Val{ true } )
    printstyledln( "Available estimators:\n"; bold = true )
    for e ∈  estdesc 
        println( e )        
    end
    return nothing    
end



function GrumpsEstimatorClass( e  )
    which = findfirst( x -> x  >: typeof(e), GrumpsEstimatorClasses )
    return which == nothing ? "unknown" : GrumpsEstimatorClasses[ which ]
end


"""
    Estimators( elaborate = false )

Prints a list of available estimators.  The argument indicates whether a lot of features should be printed 
or few.
"""
Estimators( elaborate = false ) = Estimators( Val( elaborate ) )


StringSymbol(x) = String( Symbol( x ) )


function show( io :: IO, ed :: EstimatorDescription )
    printstyledln( ed.name ; color = :red )
    printstyled( @sprintf( "   %50s: ", "Symbol used" ); color = :blue); println( ":", ed.symbol )
    e = Estimator( ed.symbol )
    for (funk,desc) ∈ [ (GrumpsEstimatorClass, "Type of estimator"),
                        (inisout, "Inner and outer objective functions are the same"),
                        (usesmicrodata, "Uses micro data"), 
                        (usesmacrodata, "Uses macro data"), 
                        (usespenalty, "Uses penalty term"), 
                        (usesmicromoments, "Uses micro moments")
                        ]
        printstyled( @sprintf( "   %50s: ", desc ); color = :blue );  println( funk( e ) )
    end
    return nothing
end
