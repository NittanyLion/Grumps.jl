function Estimator( s :: String )
    s = lowercase( s )
    println( estdesc )
    val = Vector{Float64}( undef, length(estdesc) )
    for e ∈ eachindex( estdesc )
        fn = findnearest( s, estdesc[e].descriptions, Levenshtein() )
        val[e] = fn[1] == nothing ? typemax(F64) : Levenshtein()( s, fn[1] )
    end
    winner = argmin( val )
    @info "identified $(estdesc[winner].name) as the estimator intended"
    return Estimator( Val( estdesc[winner].symbol ) )
end
