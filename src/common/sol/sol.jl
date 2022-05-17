




function SetResult!( sol :: GrumpsSolution{T}, e :: Estimator, d ::Data{T}, o :: OptimizationOptions, seo :: StandardErrorOptions, result, fgh :: GrumpsFGH{T}  ) where {T<:Flt}
    @warn "SetResult! not written yet"
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