function CheckSanitySpecific( e::GrumpsPenalized, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}
        
    if dimmom( d ) == dimβ( d )
        @info "your product level moments are exactly identified, so trying to switch you to MLE"
        return CheckSanitySpecific( GrumpsVanillaEstimator(), d, o, θstart, seo )
    end
    @ensure dimmom( d ) > dimβ( d ) "your product level moments are underidentified"
    @ensure ( size( d.plmdata.𝒦, 1 ) > 0 && size( d.plmdata.𝒦, 2 ) > 0 )  "matrix 𝒦  has dimension 0: this means that your product level moments do not provide identification"
    @ensure d.plmdata.σ2 > 0 "variance of ξ must be positive"
    @warn "This is the full version of Grumps: the cheap version has the same limit distribution, but is less expensive computationally"
    return e
end
    
    