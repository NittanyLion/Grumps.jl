






struct IngredientsPML{T<:Flt} <: Ingredients{T}
    ranges  :: Vec{ UnitRange{Int} }
    Ωθθ     :: Mat{T}
    Ωδθ     :: VMatrix{T}
    Ωδδ     :: VMatrix{T} 
    Ωδδinv  :: VMatrix{T} 
    ΩδδinvΩδθ   :: VMatrix{T}
    Hinvθθ  :: Mat{T}
    K       :: VMatrix{T}
    Δ       :: Matrix{T}
    Ξ       :: VMatrix{T}
    KVK     :: Mat{T}
    KVΞ     :: Mat{T}
    ΞVΞ     :: Mat{T}
    AinvB   :: VMatrix{T}
    AinvC   :: VMatrix{T}
    Xstar   :: Mat{T}
    Ystar   :: Mat{T}
    Zstar   :: Mat{T}
end


function Ingredients( sol :: Solution{T}, e :: GrumpsPMLEstimator, d :: GrumpsData{T}, fgh :: FGH{T}, seo :: StandardErrorOptions  ) where {T<:Flt}
    markets = 1:dimM( d )
    ranges = Ranges( dimδm( d ) )
    Ωθθ = sum( fgh.market[m].outside.Hθθ for m ∈ markets )
    Ωδθ = [ fgh.market[m].outside.Hδθ for m ∈ markets ]
    Ωδδ = [ fgh.market[m].inside.Hδδ for m ∈ markets ]
    Ωδδinv = [ inv( Ωδδ[m] ) for m ∈ markets ]
    ΩδδinvΩδθ = [ Ωδδinv[m] * Ωδθ[m] for m ∈ markets ]


    K = [ d.plmdata.𝒦[ ranges[m], : ] for m ∈ markets ]
    Q = sum( Ωδθ[m]' * Ωδδinv[m] * K[m] for m ∈ markets )
    Δ = inv( I + sum( K[m]' * Ωδδinv[m] * K[m] for m ∈ markets ) )
    Hinvθθ =  inv( Ωθθ - sum( ΩδδinvΩδθ[m]' * Ωδθ[m] for m ∈ markets ) +  Q * Δ * Q' )
    

    cholera = cholesky( Symmetric( Ωθθ ) ) 
    C = [ ( cholera.L \ Ωδθ[m]' )' for m ∈ markets ]
    AinvB = [ Ωδδinv[m] * K[m] for m ∈ markets ]
    AinvC = [ Ωδδinv[m] * C[m] for m ∈ markets ]
    BAB = sum( K[m]' * AinvB[m] for m ∈ markets )
    BAC = sum( K[m]' * AinvC[m] for m ∈ markets )
    CAC = sum( C[m]' * AinvC[m] for m ∈ markets )
    Xstar = - inv( I + BAB + BAC * inv( I - CAC ) * BAC' )
    Ystar = - inv( I - CAC + BAC' * inv( I + BAB ) * BAC )
    Zstar = - inv( I + BAB ) * BAC * Ystar   

    δ = getδcoef( sol ) 
    β = getβcoef( sol ) 
    ξ = δ - d.plmdata.𝒳 * β 
    KVK = VarianceSum( d.plmdata.𝒦, ξ, d.plmdata.𝒦, Val( seo.type ) )
    X̂ = d.plmdata.𝒳̂
    Ξ = pinv( X̂ )
    KVΞ = VarianceSum( d.plmdata.𝒦, ξ, Ξ', Val( seo.type ) )
    ΞVΞ = VarianceSum( Ξ', ξ, Ξ', Val( seo.type ) )

    
    return IngredientsPML{T}(
        ranges, Ωθθ, Ωδθ, Ωδδ, Ωδδinv, ΩδδinvΩδθ, Hinvθθ,
        K, Δ, [ Ξ[ :, ranges[m] ] for m ∈ markets ],
        KVK, KVΞ, ΞVΞ,
        AinvB, AinvC, Xstar, Ystar,Zstar )
end







function Meat( :: GrumpsPMLEstimator, ::Val{:δδ}, m :: Int, m2 :: Int, ing :: Ingredients{T}  ) where {T<:Flt} 
    R = ing.K[m] * ing.KVK * ing.K[m2]'
    m == m2 || return R
    return R + ing.Ωδδ[m]
end

Bread( :: GrumpsPMLEstimator, ::Val{:θθ}, ing :: Ingredients{T} ) where {T<:Flt} = ing.Hinvθθ

function Bread( :: GrumpsPMLEstimator, ::Val{:δθ}, m :: Int, m2 :: Int, ing :: Ingredients{T} ) where {T<:Flt}
    Q = sum( ing.K[m2]' * inv.ΩδδinvΩδθ[m2] for m2 ∈  eachindex( ing.K ) )
    return - ( ing.ΩδδinvΩδθ[m] - ing.Ωδδinv[m] * ing.K[m] * ing.Δ * Q ) * ing.Hinvθθ
end

function Bread( :: GrumpsPMLEstimator, ::Val{:δδ}, m :: Int, m2 :: Int, ing :: Ingredients{T} ) where {T<:Flt}
    R = ing.AinvB[m] * ing.Xstar * ing.AinvB[m2]' -
        ing.AinvC[m] * ing.Ystar * ing.AinvC[m2]' -
        ing.AinvB[m] * ing.Zstar * ing.AinvC[m2]' -
        ing.AinvC[m] * (ing.Zstar') * ing.AinvB[m2]'
    m == m2 || return R
    return R + ing.Ωδδinv[m]
end
