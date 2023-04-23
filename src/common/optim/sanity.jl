


@todo 3 "need more sanity checks"

function CheckSanity( anyth, d, o, θstart, seo ) 
end

function CheckSanity( d :: GrumpsData{T} ) where {T<:Flt}
    @ensure length( d.marketdata ) > 0  "need at least one market"
end


function CheckSanity( o :: OptimizationOptions )

end


function CheckSanity( seo :: StandardErrorOptions )
end

function CheckSanity( e :: Estimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}

    CheckSanity( Val( Symbol(e) ), d, o, θstart, seo )  # check sanity for issue specific to an estimator
    for a ∈ [ d, o, seo ]
        CheckSanity( a )
    end
end