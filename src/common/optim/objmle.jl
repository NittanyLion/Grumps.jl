   
@todo 2 "figure out when to recompute"
@todo 4 "for all estimators, note that frugal is not compatible with for threads; need spawns"


function ObjectiveFunctionθ1!( 
    fgh         :: GrumpsMarketFGH{T},
    θ           :: Vec{ T }, 
    δ           :: Vec{ T },
    e           :: GrumpsMLE, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions,
    s           :: GrumpsSpace{T},
    computeF    :: Bool,
    computeG    :: Bool,
    computeH    :: Bool,
    m           :: Int                              
    ) where {T<:Flt}

    recompute =  s.currentθ ≠ θ || mustrecompute( s.marketspace[m] )
    recompute && AθZXθ!( θ, e, d, o, s, m ) 

    δ .= zero( T )

    # if recompute
    initializelastδ!( s, m )
    # end
    

    # if computeG || computeH || !inisout( e )
        F = OutsideObjective1!(  fgh.outside, θ, δ, e, d, o, s.marketspace[m], computeF, computeG, computeH )
        if computeF
            fgh.outside.F .= F
        end
    # end

    freeAθZXθ!( e, s, o, m )
    return nothing
end




function ObjectiveFunctionθ!( 
    fgh         :: GrumpsFGH{T}, 
    F           :: FType{T},
    G           :: GType{T},
    H           :: HType{T},      
    θtr         :: Vec{ T }, 
    δ           :: Vec{ Vec{T} },
    e           :: GrumpsMLE, 
    d           :: GrumpsData{T}, 
    o           :: OptimizationOptions,
    s           :: GrumpsSpace{T} 
    ) where {T<:Flt}

    θ = getθ( θtr, d )

    computeF, computeG, computeH = computewhich( F, G, H )


    
    SetZero!( true, F, G, H )
    markets = 1:dimM( d )

    @threads :dynamic for m ∈ markets
        ObjectiveFunctionθ1!( 
            fgh.market[m],
            θ,
            δ[m],
            e, 
            d.marketdata[m], 
            o,
            s,
            computeF,
            computeG,
            computeH,
            m                              
            ) 
    end
    copyto!( s.currentθ, θ )                                        

    if computeF
        F = sum( fgh.market[m].outside.F[1] for m ∈ markets )
    end

    if computeH && !computeG
        computeG = true
        G = zeros( T, length(θ) )
    end



    if computeG || computeH
        δθ = Vector{ Matrix{T} }(undef, markets[end] )
        @threads :dynamic for m ∈ markets
            δθ[m] = - fgh.market[m].inside.Hδδ \ fgh.market[m].inside.Hδθ
        end
    
        G[:] = sum( fgh.market[m].outside.Gθ +  δθ[m]' * fgh.market[m].outside.Gδ for m ∈ markets )
        if computeH
            prd = Vector{ Matrix{T} }(undef, markets[end] )
            @threads :dynamic for m ∈ markets
                prd[m] = δθ[m]' * fgh.market[m].outside.Hδθ
            end
            H[ : ] = sum( fgh.market[m].outside.Hθθ 
                        + prd[m]
                        + prd[m]'
                        + δθ[m]' * fgh.market[m].outside.Hδδ * δθ[m] 
                            for m ∈ markets )
        end
        ExponentiationCorrection!( G, H, θ, dimθz( d ) )

    end

    return F
end



