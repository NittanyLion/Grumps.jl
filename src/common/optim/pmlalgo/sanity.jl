function CheckSanitySpecific( ::GrumpsPenalized, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}
        
    @ensure ( size( d.plmdata.𝒦, 1 ) > 0 && size( d.plmdata.𝒦, 2 ) > 0 )  "matrix 𝒦  has dimension 0: please do not use the penalized estimator without penalization; use MLE instead"
    @ensure d.plmdata.σ > 0 "variance of ξ must be positive"
end
    
    