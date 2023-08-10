

"""
OutsideObjective1!(  
    fgh         :: GrumpsSingleFGH{T}, 
    θ           :: Vec{T},
    δ           :: Vec{T},
    e           :: GrumpsCheapEstimator, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions, 
    s           :: GrumpsMarketSpace{T},
    m           :: Int, 
    computeF    :: Bool, 
    computeG    :: Bool, 
    computeH    :: Bool 
    )

Outside single market objective function for the Mixed Logit Estimator.  
Since the inside and outside objective functions coincide there is no
reason to recompute Ωδδ, Ωδθ
"""
OutsideObjective1!(  
    fgh         :: GrumpsSingleFGH{T}, 
    θ           :: Vec{T},
    δ           :: Vec{T},
    e           :: GrumpsCheapEstimator, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions, 
    s           :: GrumpsMarketSpace{T}, 
    m           :: Int,
    computeF    :: Bool, 
    computeG    :: Bool, 
    computeH    :: Bool 
    ) where {T<:Flt}   =  OutsideObjective1!( fgh, θ, δ, GrumpsMDLEEstimatorInstance, d, o, s, m, computeF, computeG, computeH )


# the next few functions contain the contribution to the objective function for the cheap Grumps Estimator
# relative to the MDLE estimator

function Πof( e :: GrumpsCheapEstimator, 𝒦 :: Mat{T}, δ :: Vec{ Vec{T} } ) where {T<:Flt}
    ranges = Ranges( δ )
    Kδ = sum( 𝒦[ranges[m],:]' * δ[m] for m ∈ eachindex( δ ) )
    return 0.5 * dot( Kδ, Kδ )
end

function Πgrad!( G :: Vec{T}, e :: GrumpsCheapEstimator, 𝒦 :: Mat{T}, δ :: Vec{ Vec{T} }, δθ :: Vec{ Mat{T} } ) where {T<:Flt}
    ranges = Ranges( δ )
    Kδ = sum( 𝒦[ranges[m],:]' * δ[m] for m ∈ eachindex( δ ) )
    A = sum( δθ[m]' * 𝒦[ranges[m],:] for m ∈ eachindex( δ ) )
    G[:] +=  A * Kδ
    return nothing
end

function Πhess!( H :: Mat{T}, e :: GrumpsCheapEstimator, 𝒦 :: Mat{T}, δ :: Vec{ Vec{T} }, δθ :: Vec{ Mat{T} } )  where {T<:Flt}
    ranges = Ranges( δ )
    A =sum( δθ[m]' * 𝒦[ranges[m],:] for m ∈ eachindex( δ ) )
    # @info ("Hess $(sum(A)) $(𝒦'𝒦)   $(sum(sum(δθ[m]'δθ[m]) for m ∈ eachindex( δθ ) )) ")    
    H[:,:] += A * A'
    return nothing
end
    
