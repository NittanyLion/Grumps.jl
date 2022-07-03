



"""
    Estimator( s :: String )

Creates and returns a GrumpsEstimator type.  Grumps is reasonably good at figuring out what it is that you want, so e.g.
*Estimator( "maximum likelihood" )* gives you the unpenalized Grumps maximum likelihood estimator.

The estimators currently programmed include:
* the full Grumps estimator
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

*:pml* the full Grumps maximum likelihood estimator  

*:vanilla* the unpenalized Grumps maximum likelihood estimator

*:shareconstraint* the unpenalized Grumps maximum likelihood estimator with share constraints

*:gmm* GMM estimator that uses both micro and macro moments

*:mixedlogit* mixed logit maximum likelihood estimator
"""
Estimator( s :: Symbol ) = Estimator( Val( s ) )


"""
    Estimators( )

Prints a list of available estimators.
"""
function Estimators()
    printstyledln( "Available estimators:\n"; bold = true )
    for e ∈ eachindex( estdesc )
        printstyled( @sprintf( "%30s", estdesc[e].name ); color = :red )
        printstyledln( "  :", estdesc[e].symbol; color = :blue)
    end
    return nothing
end

