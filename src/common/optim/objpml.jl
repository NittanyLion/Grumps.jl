for f ∈ [ "types", "algo", "opt", "ui", "util" ]
    include( "pmlalgo/$(f).jl" )
end  

@todo 2 "figure out when to recompute"
@todo 4 "call delta objective function outside across markets"

function ObjectiveFunctionθ1!( 
    fgh         :: PMLMarketFGH{T},
    θ           :: Vec{ T }, 
    δ           :: Vec{ T },
    e           :: GrumpsPenalized, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions,
    ms          :: GrumpsMarketSpace{T},
    computeF    :: Bool,
    computeG    :: Bool,
    computeH    :: Bool,
    m           :: Int                              
    ) where {T<:Flt}


    F = OutsideObjective1!(  fgh.outside, θ, δ, e, d, o, ms, computeF, computeG, computeH )
    if computeF
        fgh.outside.F .= F
    end

    return nothing
end




function ObjectiveFunctionθ!( 
    fgh         :: PMLFGH{T}, 
    F           :: FType{T},
    G           :: GType{T},
    H           :: HType{T},      
    θtr         :: Vec{ T }, 
    δ           :: Vec{ Vec{T} },
    e           :: GrumpsPenalized, 
    d           :: GrumpsData{T}, 
    o           :: OptimizationOptions,
    s           :: GrumpsSpace{T} 
    ) where {T<:Flt}

    θ = getθ( θtr, d )

    computeF, computeG, computeH = computewhich( F, G, H )


    
    SetZero!( true, F, G, H )
    markets = 1:dimM( d )
    for m ∈ markets
        δ[m] .= zero( T )
    end

    if !memsave( o )
        for m ∈ markets
            AθZXθ!( θ, e, d.marketdata[m], o, s, m )
        end
    end

    grumpsδ!( fgh, θ, δ, e, d, o, s )

    @threads :dynamic for m ∈ markets
        local recompute = memsave( o )

        local memslot = recompute ? AθZXθ!( θ, e, d.marketdata[m], o, s, m ) : m
        ObjectiveFunctionθ1!( 
            fgh.market[m],
            θ,
            δ[m],
            e, 
            d.marketdata[m], 
            o,
            s.marketspace[memslot],
            computeF,
            computeG,
            computeH,
            m                              
            ) 
        
        recompute && freeAθZXθ!( e, s, o, memslot )

    end

    copyto!( s.currentθ, θ )                                        

    ranges = Ranges( δ )
    Kδ = [ d.plmdata.𝒦[ranges[m],:]'δ[m] for m ∈ markets ]

    if computeF
        F = sum( fgh.market[m].outside.F[1] + 0.5 * dot( Kδ[m], Kδ[m] ) for m ∈ markets )
    end

    if computeH && !computeG
        computeG = true
        G = zeros( T, length(θ) )
    end



    if computeG || computeH
        M = length( markets )
        # δθ = Vector{ Matrix{T} }( undef, M )
        # HinvK = Vector{ Matrix{T} }( undef, M )
        K = [ view( d.plmdata.𝒦, ranges[m], : ) for m ∈ markets ]
        Hδθ = [ fgh.market[m].outside.Hδθ for m ∈ markets ]
        Hδδ = [ fgh.market[m].inside.Hδδ for m ∈ markets ]
        # @threads :dynamic for m ∈ markets
        #     @ensure fgh.market[m].inside === fgh.market[m].outside "whoops"
        #     HinvK[m] = Hδδ[m] \ K[m]
        #     δθ[m] = - Hδδ[m] \ Hδθ[m]
        # end
        # ℛ = sum( HinvK[m]'Hδθ[m] for m ∈ markets )
        # Δ = ( I + sum( K[m]' * HinvK[m] for m ∈ markets ) ) \ ℛ
        # @threads :dynamic for m ∈ markets
        #     δθ[m] += HinvK[m] * Δ 
        # end
        dδ = dimδm( d );  dθ = dimθ( d )
        δθ = [ zeros( T, dδ[m], dθ ) for m ∈ markets ]
        Z = [ zeros( T, size( K[1], 2 ), dδ[m] ) for m ∈ markets ]
        vectors, values, QG, QK = HeigenQgQK( Hδδ, Hδθ, [ K[m] for m ∈ markets ] )
        ntr_find_direction(  δθ,  QG, QK, values,  vectors, zero(T), Z )


        # println( "should be zero:  ", sum( δθ[m]' * fgh.market[m].inside.Gδ for m ∈ markets ) )
        G[:] = sum( fgh.market[m].outside.Gθ +  δθ[m]' * fgh.market[m].outside.Gδ for m ∈ markets )
        if computeH
            # H[ : ] = sum( fgh.market[m].outside.Hθθ 
            #             + prd[m]
            #             + prd[m]'
            #             + δθ[m]' * fgh.market[m].outside.Hδδ * δθ[m] 
            #             + Kdδθ[m]' * Kdδθ[m]
            #                 for m ∈ markets ) 
            # H[ :, : ] = sum( fgh.market[m].outside.Hθθ 
            #     + prd[m]
            #     + prd[m]'
            #     + δθ[m]' * fgh.market[m].outside.Hδδ * δθ[m] 
            #         for m ∈ markets ) + Kdδθ'Kdδθ
            H[ :, : ] = sum( fgh.market[m].outside.Hθθ + δθ[m]'Hδθ[m] for m ∈ markets ) 
            Symmetrize!( H )
        end
        ExponentiationCorrection!( G, H, θ, dimθz( d ) )

    end

    if !memsave( o )
        for m ∈ markets
            freeAθZXθ!( e, s, o, m )
        end
    end
    return F
end



