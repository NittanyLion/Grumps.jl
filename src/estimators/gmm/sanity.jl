function CheckSanitySpecific( e::GrumpsGMMEstimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}
        
    advisory( "The gmm estimator is inferior\nand the code is unfinished\nso do not use this estimator\nexcept to improve the code or\nif you are a masochist." )
    return e
end
    
    