
abstract type Solution{T<:Flt} end

@todo 3 "still have to define the GrumpsSolution type"

struct GrumpsSolution{T<:Flt} <: Solution{T}
    function GrumpsSolution( T2 :: Type )
        new{T2}()
    end 
end


function Solution( e :: GrumpsEstimator, d :: GrumpsData{T}, seo :: StandardErrorOptions ) where {T<:Flt}
    println( "got here" )
    @warn "Solution not coded yet"
    return GrumpsSolution(T)
end
