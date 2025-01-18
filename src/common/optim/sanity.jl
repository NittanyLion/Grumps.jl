


@todo 3 "need more sanity checks"

function CheckSanitySpecific( anyth, d, o, θstart, seo ) 
    return anyth
end



function CheckSanity( epassed :: Estimator, con :: AbstractConstraint{T}, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}
    e = CheckSanitySpecific( epassed, d, o, θstart, seo )  # check sanity for issue specific to an estimator
    Constrained( con ) && @ensure handlesconstraints( e ) "Estimator $e cannot handle constraints"
    mktthreads( o ) == 1 && inthreads( o ) == 1 && advisory( "you are only using one Julia thread\nwhich is typically slow:\nstart Julia with e.g. julia -t 8 to get 8 threads" )
    return e
end


#
CheckSanity( epassed :: Estimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt} =
    CheckSanity( epassed, NoConstraint{T}(), d, o, θstart, seo )