

function Momentθ1!( 
    fgh                                 :: GMMMarketFGH{T},
    θ                                   :: A1{T},  
    δ                                   :: A1{T},
    e                                   :: GrumpsGMM, 
    d                                   :: GrumpsMarketData{T}, 
    𝒦m                                  :: AA2{T},
    o                                   :: OptimizationOptions,
    s                                   :: GrumpsSpace{T},
    computeF                            :: Bool,
    computeG                            :: Bool,
    m                                   :: Int
    ) where {T<:Flt}

    recompute =  s.currentθ ≠ θ || mustrecompute( s.marketspace[m] )

    recompute && AθZXθ!( θ, e, d, o, s, m ) 
    δ .= zero( T )

    initializelastδ!( s, m )
    grumpsδ!( fgh.inside, θ, δ, e, d, o, s.marketspace[m], m )      # compute δs in the inner loop and store them in s.δ

    F = OutsideMoment1!(  fgh, θ, δ, e, d, 𝒦m, o, s.marketspace[m], computeF, computeG )

    freeAθZXθ!( e, s, o, m )
    return nothing

end



function ObjectiveFunctionθ!( 
    fgh         :: GMMFGH{T}, 
    F           :: FType{T},
    Garg        :: GType{T},
    H           :: HType{T},      
    θtr         :: Vec{ T }, 
    δ           :: Vec{ Vec{T} },
    e           :: GrumpsGMM, 
    d           :: GrumpsData{T}, 
    o           :: OptimizationOptions,
    s           :: GrumpsSpace{T} 
    ) where {T<:Flt}

    θ = getθ( θtr, d )

    computeF, computeG, computeH = computewhich( F, Garg, H )


    
    markets = 1:dimM( d )
    ranges = Ranges( dimδm( d ) )
    
    @threads :dynamic for m ∈ markets
        Momentθ1!( 
            fgh.market[m],
            θ,
            δ[m],
            e, 
            d.marketdata[m], 
            view( d.plmdata.𝒦, ranges[m], : ),
            o,
            s,
            computeF,
            computeG,
            m                              
            ) 
    end
    copyto!( s.currentθ, θ )                                         # copy the current θ

    mom = sum( fgh.market[m].mom for m ∈ markets )
    # println( "moment = $mom")
    if computeF
        F = dot( mom, mom )
    end

    if !computeG && !computeH
        return F
    end


    δθ = Vec{ Mat{T} }( undef, markets[end] )
    insides = 1:dimδ( d )
    parameters = 1:dimθ( d )

    @threads :dynamic for m ∈ markets
        δθ[m] = - fgh.market[m].inside.Hδδ \ fgh.market[m].inside.Hδθ
    end

    momdθ = sum( fgh.market[m].momdθ for m ∈ markets )
    cross = sum( fgh.market[m].momdδ * δθ[m] for m ∈ markets )
    both = momdθ + cross

    G = 2.0 * both'  * mom


    if computeH
        H[:,:] = 2.0 * both' * both
    end

    ExponentiationCorrection!( G, H, θ, dimθz( d ) )

    if computeG
        copyto!( Garg, G )
    end

    # computeG && println( "gradient = $G")
    # computeH && println( "Hessian = $(round.(H;digits=5)) ")
    return F
end

