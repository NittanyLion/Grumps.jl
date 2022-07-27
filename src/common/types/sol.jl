
abstract type Solution{T<:Flt} end


mutable struct GrumpsEstimate{T<:Flt}
    name    ::      String
    coef    ::      T
    stde    ::      FType{T}
    tstat   ::      FType{T}

    function GrumpsEstimate( name :: String, est :: T2, stde :: FType{T2} = nothing, tstat :: FType{T2} = nothing  ) where {T2<:Flt}
        new{T2}( name, est, stde, tstat )
    end

end


mutable struct GrumpsConvergence{T<:Flt}
    minimum                 :: T
    iterations              :: Int
    iteration_limit_reached :: Bool
    converged               :: Bool
    f_converged             :: Bool
    g_converged             :: Bool
    x_converged             :: Bool
    f_calls                 :: Int
    g_calls                 :: Int
    h_calls                 :: Int
    f_trace                 :: Vec{T}
    g_norm_trace            :: Vec{T}
    x_trace                 :: Vec{ Vec{T} }

    function GrumpsConvergence( T2 :: Type )
        new{T2}( typemax( T2 ), 0, false, false, false, false, false, 0, 0, 0, zeros(T2,0), zeros(T2,0), [ zeros(T2,0) ] )
    end
end




mutable struct GrumpsSolution{T<:Flt} <: Solution{T}
    θ   :: Vec{ GrumpsEstimate{T} }
    β   :: Vec{ GrumpsEstimate{T} }
    δ   :: Vec{ GrumpsEstimate{T} }
    convergence :: GrumpsConvergence{T}

    function GrumpsSolution( T2 :: Type, θn :: Vec{String}, βn :: Vec{String}, δn :: Vec{String} )
        θ = [ GrumpsEstimate( θn[i], typemax( T2 ), nothing, nothing ) for i ∈ eachindex( θn ) ]
        β = [ GrumpsEstimate( βn[i], typemax( T2 ), nothing, nothing ) for i ∈ eachindex( βn ) ]
        δ = [ GrumpsEstimate( δn[i], typemax( T2 ), nothing, nothing ) for i ∈ eachindex( δn ) ]
        new{T2}(  θ, β, δ, GrumpsConvergence( T2 ) )
    end 
end


for fld ∈ fieldnames( GrumpsConvergence )
    eval(quote
        $fld( c :: GrumpsConvergence ) = c.$fld
        $fld( s :: GrumpsSolution ) = $fld( s.convergence )
    end )
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

"""
    getθcoef( sol :: GrumpsSolution )

Returns a vector of θ coefficients
"""
getθcoef( sol ) = getcoef.( getθ( sol) )

"""
    getδcoef( sol :: GrumpsSolution )

Returns a vector of δ coefficients
"""
getδcoef( sol ) = getcoef.( getδ( sol) )


"""
    getβcoef( sol :: GrumpsSolution )

Returns a vector of β coefficients
"""
getβcoef( sol ) = getcoef.( getβ( sol) )

