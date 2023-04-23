


@todo 3 "need more sanity checks"

function CheckSanity( anyth, d, o, θstart, seo ) 
end

# this checks the sanity of making certain combinations; sanity of each individual component should be checked on creation.
#
function CheckSanity( e :: Estimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}
    CheckSanity( Val( Symbol(e) ), d, o, θstart, seo )  # check sanity for issue specific to an estimator



end