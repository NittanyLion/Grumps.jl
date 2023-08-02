



# these are defaults and may be overwritten elsewhere
Meat( :: GrumpsEstimator, ::Val{:θ}, ::Val{:θ}, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt} = ing.Ωθθ
Meat( :: GrumpsEstimator, ::Val{:δ}, ::Val{:θ}, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T}  ) where {T<:Flt} = ing.Ωδθ[m]
Meat( e, ::Val{:θ}, ::Val{:δ}, m, m2, ing ) = Meat( e, Val(:δ), Val(:θ), m2, m, ing )'

function Meat( :: GrumpsEstimator, ::Val{:δ}, ::Val{:δ}, m :: Int, m2 :: Int, ing :: Ingredients{T}  ) where {T<:Flt} 
    R = ing.K[m] * ing.KVK * ing.K[m2]'
    m == m2 || return R
    return R + ing.Ωδδ[m]
end




Bread( :: GrumpsEstimator, ::Val{:θ}, ::Val{:θ}, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt} = ing.Hinvθθ

function Bread( :: GrumpsEstimator, ::Val{:δ}, ::Val{:θ}, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    Q = sum( ing.K[m2]' * ing.ΩδδinvΩδθ[m2] for m2 ∈  eachindex( ing.K ) )
    return - ( ing.ΩδδinvΩδθ[m] - ing.Ωδδinv[m] * ing.K[m] * ing.Δ * Q ) * ing.Hinvθθ
end

function Bread( :: GrumpsEstimator, ::Val{:δ}, ::Val{:δ}, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    R = ing.AinvB[m] * ing.Xstar * ing.AinvB[m2]' -
        ing.AinvC[m] * ing.Ystar * ing.AinvC[m2]' -
        ing.AinvB[m] * ing.Zstar * ing.AinvC[m2]' -
        ing.AinvC[m] * (ing.Zstar') * ing.AinvB[m2]'
    m == m2 || return R
    return R + ing.Ωδδinv[m]
end

Bread( e, ::Val{:θ}, ::Val{:δ}, m, m2, ing  ) = Bread( e, Val(:δ), Val(:θ), m2, m, ing )'


function GrumpsVal( m :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    m == 0 && return Val(:θ)
    m == dimM(ing) + 1 && return Val(:β)
    return Val(:δ)
end


Meat( e, m, m2, ing ) = Meat( e, GrumpsVal( m, ing ), GrumpsVal( m2,ing ), m, m2, ing )
Bread( e, m, m2, ing ) = Bread( e, GrumpsVal( m, ing ), GrumpsVal( m2, ing ), m, m2, ing )


function VarEst( e :: GrumpsEstimator, ::Val{ :β }, ::Val{:β}, 𝓂 :: Int, 𝓂2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    markets = 1:dimM( ing );  markets0 = 0:dimM( ing )
    ΞAδθ = sum( ing.Ξ[m] * Bread( e, m, 0, ing ) for m ∈ markets )
    ΞAδδ = [ sum( ing.Ξ[m] * Bread( e, m, m2, ing ) for m ∈ markets ) for m2 ∈ markets ]
    V = ing.ΞVΞ
    if typeof( e ) <: GrumpsPenalized 
        V -= let ΞAK = sum( ΞAδδ[m]  * ing.K[m] for m ∈ markets )
                ΞAK * ing.KVΞ + ing.KVΞ' * ΞAK'
             end
    end
    V += ΞAδθ * Meat( e, 0, 0, ing ) * ΞAδθ'
    for m ∈ markets
        V +=  let C = ΞAδθ * Meat( e, 0, m, ing ) * ΞAδδ[m]'
                C + C'
              end
    end
    V += sum( ΞAδδ[m] * Meat( e, m, m2, ing ) * ΞAδδ[m2]' for m ∈ markets, m2 ∈ markets )
    return V
end



function VarEstβhelper( e :: GrumpsEstimator, 𝓂 :: Int , ing :: GrumpsIngredients{T} ) where {T<:Flt}
    return  sum(   
        sum( Bread( e, 𝓂, m, ing ) * Meat( e, m, m2, ing ) for m ∈ 0 : dimM( ing ) ) * 
        sum( Bread( e, m2, m, ing ) * ing.Ξ[m]' for m ∈ 0 : dimM( ing ) )
        for m2 ∈ 0 : dimM( ing )
        )
end


VarEst( e :: GrumpsEstimator, ::Val{:θ}, ::Val{:β}, 𝓂 :: Int, 𝓂2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt} = VarEstβhelper( e, 0, ing )
VarEst( e :: GrumpsEstimator, ::Val{:δ}, ::Val{:β}, 𝓂 :: Int, 𝓂2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt} = VarEstβhelper( e, 𝓂, ing ) - sum( Bread( e, 𝓂, m, ing ) * ing.K[m] for m ∈ 1:dimM( ing ) ) * ing.ΞVK'
VarEst( e :: GrumpsEstimator, ::Val{:β}, ::Val{:δ}, 𝓂, 𝓂2, ing ) = VarEst( e, Val( :δ ), Val( :β ), 𝓂2, 𝓂, ing )'



VarEst( e :: GrumpsEstimator, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} )  where {T<:Flt} =
    VarEst( e, GrumpsVal( m, ing ), GrumpsVal( m2, ing ), m, m2, ing )


VarEst( e :: GrumpsEstimator, ::Union{ Val{:θ}, Val{:δ} }, ::Union{ Val{:θ}, Val{:δ} }, 𝓂 :: Int, 𝓂2 :: Int, ing ::GrumpsIngredients{T} ) where {T<:Flt} = sum( Bread( e, 𝓂, i, ing ) * Meat( e, i, j, ing ) * Bread( e, j, 𝓂, ing ) for i ∈ 0:dimM( ing ), j ∈ 0:dimM( ing ) )


function sqrt_robust( v :: T ) where {T<:Flt}
    try sqrt( v )
    catch
        NaN
    end
end

function se( e, ing :: GrumpsIngredients{T}, m :: Int ) where {T<:Flt}
    V = VarEst( e, m, m, ing );  
    return [ sqrt_robust( V[j,j] ) for j ∈ axes( V, 1 ) ]
end


se( e, ing :: GrumpsIngredients{T}, ::Val{:β} ) where {T<:Flt} = se( e, ing, dimM( ing ) + 1 )
se( e, ing :: GrumpsIngredients{T}, ::Val{:θ} ) where {T<:Flt} = se( e, ing, 0 )
se( e, ing :: GrumpsIngredients{T}, ::Val{:δ} ) where {T<:Flt} = vcat( [ se( e, ing, m ) for m ∈ 1:dimM( ing ) ]... )


function ses!( sol :: Solution{T}, e :: GrumpsEstimator, d :: GrumpsData{T}, f :: FGH{T}, seo :: StandardErrorOptions ) where {T<:Flt}
    seo.computeβ || seo.computeθ || seo.computeδ || return nothing
    ing = Ingredients( sol, Val( seprocedure( e ) ), d , f, seo  ) 
    ing == nothing && return nothing
    
    for ( ψ, computeψ, solψ ) ∈ [ (:θ, seo.computeθ, sol.θ), (:β,seo.computeβ,sol.β), (:δ,seo.computeδ,sol.δ) ]
        computeψ || continue
        local seψ = se( e, ing, Val( ψ ) )
        @assert length( seψ ) == length( solψ )
        for j ∈ eachindex( seψ )
            solψ[j].stde = seψ[j]
            solψ[j].tstat = solψ[j].coef / solψ[j].stde
        end
    end
    return nothing
end

