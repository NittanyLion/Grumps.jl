
abstract type Solution{T<:Flt} end

@todo 3 "still have to define the GrumpsSolution type"

mutable struct GrumpsEstimate{T<:Flt}
    name    ::      String
    coef    ::      T
    stde    ::      FType{T}
    tstat   ::      FType{T}

    function GrumpsEstimate( name :: String, est :: T2, stde :: FType{T2} = nothing, tstat :: FType{T2} = nothing  ) where {T2<:Flt}
        new{T2}( name, est, stde, tstat )
    end

end


mutable struct GrumpsSolution{T<:Flt} <: Solution{T}
    θ   :: Vec{ GrumpsEstimate{T} }
    β   :: Vec{ GrumpsEstimate{T} }
    δ   :: Vec{ GrumpsEstimate{T} }


    function GrumpsSolution( T2 :: Type, θn :: Vec{String}, βn :: Vec{String}, δn :: Vec{String} )
        θ = [ GrumpsEstimate( θn[i], typemax( T2 ), nothing, nothing ) for i ∈ eachindex( θn ) ]
        β = [ GrumpsEstimate( βn[i], typemax( T2 ), nothing, nothing ) for i ∈ eachindex( βn ) ]
        δ = [ GrumpsEstimate( δn[i], typemax( T2 ), nothing, nothing ) for i ∈ eachindex( δn ) ]
        new{T2}(  θ, β, δ )
    end 
end


function Solution( e :: GrumpsEstimator, d :: GrumpsData{T}, seo :: StandardErrorOptions ) where {T<:Flt}
    @info "initializing solution"
    vn = d.variablenames
    
    return GrumpsSolution( T , vn.θnames , vn.βnames, vn.δnames )
end



