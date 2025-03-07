# load optimization code
for f ∈ [ "types", "algo", "ui", "util", "opt" ]
    include( "cleeralgo/$(f).jl" )
end  


# this computes the οutside objective function for a single market (excluding the penalty term)
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


    F = OutsideObjective1!(  fgh.outside, θ, δ, e, d, o, ms, m, computeF, computeG, computeH )
    if computeF
        fgh.outside.F .= F
    end

    return nothing
end



# this computes the outside objective function
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
    s           :: GrumpsSpace{T},
    lastθtr     :: Vec{ T },
    lastδ       :: VVector{ T }
    ) where {T<:Flt}

    sameθ = (lastθtr == θtr) ? true : false
    @debug "same θ?   $sameθ  $(norm(lastθtr-θtr))"
    copyto!( lastθtr, θtr )

    θ = getθ( θtr, d )

    computeF, computeG, computeH = computewhich( F, G, H )


    
    SetZero!( true, F, G, H )
    markets = 1:dimM( d )

    # for m ∈ markets
        # δ[m] .= zero( T )
    # end

    if !memsave( s )
        for m ∈ markets
            AθZXθ!( θ, e, d.marketdata[m], o, s, m )
        end
    end

    # compute δ
    if !sameθ 
        # fill!.( δ, zero( T ) )
        copyto!.( δ, lastδ )
        grumpsδ!( fgh, θ, δ, e, d, o, s )
        copyto!.( lastδ, δ )
    end

    completed = Threads.Atomic{Int}( 0 )
    sem = Semaphore( 1 )
    if progressbar( o ) 
        Base.acquire( sem )
        UpdateProgressBar( completed[] / dimM( d ) )
        Base.release( sem )
    end


    # compute the likelihood values, gradients, and Hessians
    @threads :dynamic for m ∈ markets
        mustrecompute(s) && AθZXθ!( θ, e, d.marketdata[m], o, s, m ) : m
        ObjectiveFunctionθ1!( 
            fgh.market[m],
            θ,
            δ[m],
            e, 
            d.marketdata[m], 
            o,
            s.marketspace[m],
            computeF,
            computeG,
            computeH,
            m                              
            ) 
        
        mustrecompute(s) && freeAθZXθ!( e, s, o, m )

        if progressbar( o )
            Base.acquire( sem )
            Threads.atomic_add!( completed, 1 ) 
            UpdateProgressBar( completed[] / dimM( d ) )
            Base.release( sem )
        end
    end

    copyto!( s.currentθ, θ )        

    # now add the penalty term
    ranges = Ranges( δ )
    Kδ = sum( d.plmdata.𝒦[ranges[m],:]'δ[m] for m ∈ markets )
    if computeF
        F = sum( fgh.market[m].outside.F[1] for m ∈ markets ) + 0.5 * dot( Kδ, Kδ ) 
    end

    if computeH && !computeG
        computeG = true
        G = zeros( T, length(θ) )
    end


    # compute the overall gradient and Hessian wrt θ
    if computeG || computeH
        M = length( markets )
        K = [ view( d.plmdata.𝒦, ranges[m], : ) for m ∈ markets ]
        Hδθ = [ fgh.market[m].outside.Hδθ for m ∈ markets ]
        dδ = dimδm( d );  dθ = dimθ( d )
        δθ = [ zeros( T, dδ[m], dθ ) for m ∈ markets ]
        Z = [ zeros( T, size( K[1], 2 ), dδ[m] ) for m ∈ markets ]
        Heig = ThreadsX.map( x->eigen( Symmetric( x.inside.Hδδ ) ), fgh.market )
        Q = map( x->x.vectors, Heig )
        Λ = map( x->x.values, Heig )
        QᵀG = ThreadsX.map( (x,y)->x' * y, Q, Hδθ )
        QᵀK = ThreadsX.map( (x,y)->x' * y, Q, K )
    
        DetermineDirection!( δθ, zero( T ), Q , QᵀG, QᵀK, Λ )

        G[:] = sum( fgh.market[m].outside.Gθ +  δθ[m]' * fgh.market[m].outside.Gδ for m ∈ markets )
        if computeH
            H[ :, : ] = sum( fgh.market[m].outside.Hθθ + δθ[m]'Hδθ[m] for m ∈ markets ) 
            Symmetrize!( H )
        end
        # correct for the fact that we took an exponential of the random coefficients
        ExponentiationCorrection!( G, H, θ, dimθz( d ) )

    end

    if !memsave( s )
        for m ∈ markets
            freeAθZXθ!( e, s, o, m )
        end
    end
    return F
end



