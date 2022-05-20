

function Momentθ1!( 
    fgh                                 :: GMMMarketFGH{T},
    θ                                   :: A1{T},  
    e                                   :: GrumpsGMM, 
    d                                   :: GrumpsMarketData{T}, 
    𝒦m                                  :: AA2{T},
    o                                   :: OptimizationOptions,
    s                                   :: GrumpsSpace{T},
    computeF                            :: Bool,
    computeG                            :: Bool,
    m                                   :: Int
    ) where {T<:Flt}

    recompute =  s.currentθ ≠ θ || memsave( o )

    memslot = recompute ? AθZXθ!( θ, e, d, o, s, m ) : m
    ms = s.marketspace[memslot]
    δ = 𝓏𝓈( T, dimδ( d ) )

    # if recompute
        ms.microspace.lastδ .= typemax( T )
        ms.macrospace.lastδ .= typemax( T )
        grumpsδ!( fgh.inside, θ, δ, e, d, o, ms, m )      # compute δs in the inner loop and store them in s.δ
    # else
        # @warn "did not recompute δ"
    # end
    

    # if computeG || computeH || !inisout( e )
       F = OutsideMoment1!(  fgh, θ, δ, e, d, 𝒦m, o, ms, computeF, computeG )
    # end

    freeAθZXθ!( e, s, o, memslot )
    return nothing

end



function ObjectiveFunctionθ!( 
    fgh         :: GMMFGH{T}, 
    F           :: FType{T},
    Garg        :: GType{T},
    H           :: HType{T},      
    θtr         :: Vec{ T }, 
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

    return F
end

