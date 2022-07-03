



struct IngredientsVanilla{T<:Flt} <: Ingredients{T}
    ranges  :: Vec{ UnitRange{Int} }
    Ωθθ     :: Mat{T}
    Ωδθ     :: VMatrix{T}
    Ωδδ     :: VMatrix{T} 
    Ωδδinv  :: VMatrix{T} 
    ΩδδinvΩδθ   :: VMatrix{T}
    Hinvθθ  :: Mat{T}
    K       :: VMatrix{T}
    C       :: VMatrix{T}
    Δ       :: Matrix{T}
    Ξ       :: VMatrix{T}
    KVK     :: Mat{T}
    KVΞ     :: Mat{T}
    ΞVΞ     :: Mat{T}
end


function Ingredients( sol :: Solution{T}, e :: GrumpsVanillaEstimator, d :: GrumpsData{T}, fgh :: FGH{T}, seo :: StandardErrorOptions  ) where {T<:Flt}
    markets = 1:dimM( d )
    ranges = Ranges( dimδm( d ) )
    Ωθθ = sum( fgh.market[m].outside.Hθθ for m ∈ markets )
    Ωδθ = [ fgh.market[m].outside.Hδθ for m ∈ markets ]
    Ωδδ = [ fgh.market[m].inside.Hδδ for m ∈ markets ]
    Ωδδinv = [ inv( Ωδδ[m] ) for m ∈ markets ]
    ΩδδinvΩδθ = [ Ωδδinv[m] * Ωδθ[m] for m ∈ markets ]

    K = [ d.plmdata.𝒦[ ranges[m], : ] for m ∈ markets ]
    Hinvθθ = inv( Ωθθ - sum( Ωδθ[m]' * Ωδδinv[m] * Ωδθ[m] for m ∈ markets ) )

    cholera = cholesky( Symmetric( Ωθθ ) ) 
    C = [ ( cholera.L \ Ωδθ[m]' )' for m ∈ markets ]
    Δ = inv( I - sum( C[m]' * Ωδδinv[m] * C[m] for m ∈ markets ) )

    δ = getδcoef( sol ) 
    β = getβcoef( sol ) 
    ξ = δ - d.plmdata.𝒳 * β 
    KVK = VarianceSum( d.plmdata.𝒦, ξ, d.plmdata.𝒦, Val( seo.type ) )
    Ξ = pinv( d.plmdata.𝒳̂ )
    KVΞ = VarianceSum( d.plmdata.𝒦, ξ, Ξ', Val( seo.type ) )
    ΞVΞ = VarianceSum( Ξ', ξ, Ξ', Val( seo.type ) )

    
    return IngredientsVanilla{T}(
        ranges, Ωθθ, Ωδθ, Ωδδ, Ωδδinv, ΩδδinvΩδθ, Hinvθθ,
        K, C, Δ, [ Ξ[ :, ranges[m] ] for m ∈ markets ],
        KVK, KVΞ, ΞVΞ  )
end









function Meat( :: GrumpsVanillaEstimator, ::Val{:δδ}, m :: Int, m2 :: Int, ing :: Ingredients{T}  ) where {T<:Flt} 
    R = zeros( T, size( ing.Ωδδ[m], 1), size( ing.Ωδδ[m2], 1 ) )
    m == m2 || return R
    return R + ing.Ωδδ[m]
end


Bread( :: GrumpsVanillaEstimator, ::Val{:δθ}, m :: Int, ing :: Ingredients{T} ) where {T<:Flt} = - ing.ΩδδinvΩδθ[m] * ing.Hinvθθ 

function Bread( :: GrumpsVanillaEstimator, ::Val{:δδ}, m :: Int, m2 :: Int, ing :: Ingredients{T} ) where {T<:Flt}
    R = ing.Ωδδinv[m] * ing.C[m] * ing.Δ * ing.C[m2]' * ing.Ωδδinv[m2]
    m == m2 || return R
    return R + ing.Ωδδinv[m]
end
