

"""
    Estimator( s :: String )

Creates and returns a GrumpsEstimator type.  Grumps is reasonably good at figuring out what it is that you want, so e.g.
*Estimator( "maximum likelihood" )* gives you the unpenalized Grumps maximum likelihood estimator.
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

This is one method of specifying the estimator used.  However, it unforgiving in that the exact symbol used internally must be passed, so
the *Estimator( s :: String )* method is usually a better choice.

Possible choices include:

*:plm* the penalized Grumps maximum likelihood estimator  **not implemented yet**

*:vanilla* the unpenalized Grumps maximum likelihood estimator

*:shareconstraint* the unpenalized Grumps maximum likelihood estimator with share constraints

*:gmm* GMM estimator that uses both micro and macro moments

*:mixedlogit* mixed logit maximum likelihood estimator
"""
Estimator( s :: Symbol ) = Estimator( Val( s ) )
