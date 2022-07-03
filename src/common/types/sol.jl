
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
    vn = d.variablenames
    
    return GrumpsSolution( T , vn.θnames , vn.βnames, vn.δnames )
end





"""
    getθ( sol :: GrumpsSolution )

Returns a vector of GrumpsEstimate types for θ that can be queried for results.  See  *getcoef*, *getstde*, *gettstat*, and *getname*.
"""
getθ( sol :: GrumpsSolution ) = sol.θ

"""
    getδ( sol :: GrumpsSolution )

Returns a vector of GrumpsEstimate types for δ that can be queried for results. See  *getcoef*, *getstde*, *gettstat*, and *getname*.
"""
getδ( sol :: GrumpsSolution ) = sol.δ


"""
    getβ( sol :: GrumpsSolution )

Returns a vector of GrumpsEstimate types for β that can be queried for results. See  *getcoef*, *getstde*, *gettstat*, and *getname*.
"""
getβ( sol :: GrumpsSolution ) = sol.β

"""
    getcoef( e :: GrumpsEstimate )

Returns the estimated coefficient value.
"""
getcoef( e :: GrumpsEstimate ) = e.coef

"""
    getstde( e :: GrumpsEstimate )

Returns the standard error.
"""
getstde( e :: GrumpsEstimate ) = e.stde

"""
    gettstat( e :: GrumpsEstimate )

Returns the t statistic.
"""
gettstat( e :: GrumpsEstimate ) = e.tstat

"""
    getname( e :: GrumpsEstimate )

Returns the variable name.
"""
getname( e :: GrumpsEstimate ) = e.name


getθcoef( sol ) = getcoef.( getθ( sol) )
getδcoef( sol ) = getcoef.( getδ( sol) )
getβcoef( sol ) = getcoef.( getβ( sol) )

