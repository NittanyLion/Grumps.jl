# load optimization code
for f ∈ [ "types", "algo", "opt", "ui", "util" ]
    include( "pmlalgo/$(f).jl" )
end  

@todo 2 "figure out when to recompute"
@todo 4 "call delta objective function outside across markets"

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
    s           :: GrumpsSpace{T} 
    ) where {T<:Flt}

    θ = getθ( θtr, d )

    computeF, computeG, computeH = computewhich( F, G, H )


    
    SetZero!( true, F, G, H )
    markets = 1:dimM( d )
    for m ∈ markets
        δ[m] .= zero( T )
    end

    if !memsave( s )
        for m ∈ markets
            AθZXθ!( θ, e, d.marketdata[m], o, s, m )
        end
    end

    # compute δ
    grumpsδ!( fgh, θ, δ, e, d, o, s )
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
        Hδδ = [ fgh.market[m].inside.Hδδ for m ∈ markets ]
        dδ = dimδm( d );  dθ = dimθ( d )
        δθ = [ zeros( T, dδ[m], dθ ) for m ∈ markets ]
        Z = [ zeros( T, size( K[1], 2 ), dδ[m] ) for m ∈ markets ]
        vectors, values, QG, QK = HeigenQgQK( Hδδ, Hδθ, [ K[m] for m ∈ markets ] )
        ntr_find_direction(  δθ,  QG, QK, values,  vectors, zero(T), Z )


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



