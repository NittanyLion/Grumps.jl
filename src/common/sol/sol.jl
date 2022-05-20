


@todo 3 "currently only saving θ coefficients"
@todo 2 "still need to compute standard errors"
@todo 4 "still need to do penalized estimator"

function SetResult!( sol :: GrumpsSolution{T}, e :: Estimator, d ::Data{T}, o :: OptimizationOptions, seo :: StandardErrorOptions, result, fgh :: FGH{T}  ) where {T<:Flt}
    for i ∈ eachindex( result.minimizer )
        sol.θ[i].coef = result.minimizer[i]
    end
    return nothing
end

@todo 2  "SetHighWaterMark! not written yet"
function SetHighWaterMark!( sol :: GrumpsSolution ) 
   
end


function logreport!(sol :: GrumpsSolution, msg :: AbstractString )
    @warn "logreport! not written yet"
end
 
@todo 2 "SetStatus! not written yet"

function SetStatus!( sol :: GrumpsSolution, status :: AbstractString ) 
    
end