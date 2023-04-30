function CheckSanitySpecific( e::GrumpsGMMEstimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}
        
    @warn "The gmm estimator is inferior and the code is unfinished so do not use this estimator except to improve the code or if you are a masochist."
    return e
end
    
    