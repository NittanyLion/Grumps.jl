   
@todo 2 "figure out when to recompute"
inside( fgh )       = fgh.inside
outside( fgh )      = fgh.outside




# this computes the οutside objective function for a single market (excluding the penalty term)
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

    recompute =  currentθ( s ) ≠ θ || mustrecompute( marketspace(s, m) )
    recompute && AθZXθ!( θ, e, d, o, s, m ) 

    δ .= zero( T )

    # if recompute
    initializelastδ!( s, m )
    grumpsδ!( inside( fgh ), θ, δ, e, d, o, marketspace( s, m ), m )
    # end
    

    # if computeG || computeH || !inisout( e )
    F = OutsideObjective1!(  outside( fgh ), θ, δ, e, d, o, marketspace( s, m ), m, computeF, computeG, computeH )
    if computeF
        fgh.outside.F .= F
    end
    # end

    freeAθZXθ!( e, s, o, m )
    return nothing
end

# these functions are redundant for all but the cheap Grumps estimator
Πof( e :: GrumpsMLE, 𝒦 :: Mat{T}, δ :: Vec{ Vec{T} } ) where {T<:Flt} = zero( T )
Πgrad!( G :: Vec{T}, e :: GrumpsMLE, 𝒦 :: Mat{T}, δ :: Vec{ Vec{T} }, δθ :: Vec{ Mat{T} } ) where {T<:Flt} = nothing
Πhess!( H :: Mat{T}, e :: GrumpsMLE, 𝒦 :: Mat{T}, δ :: Vec{ Vec{T} }, δθ :: Vec{ Mat{T} } ) where {T<:Flt} = nothing


# @warn "take this out"
# using Profile
# const profile_count = [ 0 ]

# this computes the outside objective function
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

    sem = Semaphore( 1 )
    completed = Threads.Atomic{Int}( 0 )
    if progressbar( o ) 
        Base.acquire( sem )
        UpdateProgressBar( completed[] / dimM( d ) )
        Base.release( sem )
    end

    # compute the likelihood values, gradients, and Hessians wrt θ
    @threads :dynamic for m ∈ markets
        # println( to[m] )
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

        if progressbar( o ) 
            Base.acquire( sem )
            Threads.atomic_add!( completed, 1 ) 
            UpdateProgressBar( completed[] / dimM( d ) )
            Base.release( sem )
        end
    end
    copyto!( s.currentθ, θ )                                        

    if computeF
        F = sum( fgh.market[m].outside.F[1] for m ∈ markets ) + Πof( e, d.plmdata.𝒦, δ )
    end

    if computeH && !computeG
        computeG = true
        G = zeros( T, length(θ) )
    end



    if computeG || computeH
        δθ = Vector{ Matrix{T} }(undef, markets[end] )
        @threads :dynamic for m ∈ markets
            δθ[m] = try - fgh.market[m].inside.Hδδ \ fgh.market[m].inside.Hδθ
            catch 
                @ensure false "Hessian with respect to δ is not invertible for market $m"
            end
        end
        G[:] = sum( fgh.market[m].outside.Gθ +  δθ[m]' * fgh.market[m].outside.Gδ for m ∈ markets ) 
        Πgrad!( G, e, d.plmdata.𝒦, δ, δθ )
        if computeH
            prd = Vector{ Matrix{T} }(undef, markets[end] )
            @threads :dynamic for m ∈ markets
                prd[m] = δθ[m]' * fgh.market[m].outside.Hδθ
            end
            H .= sum( fgh.market[m].outside.Hθθ 
                        + prd[m]
                        + prd[m]'
                        + δθ[m]' * fgh.market[m].outside.Hδδ * δθ[m] 
                            for m ∈ markets ) 
            Πhess!( H, e, d.plmdata.𝒦, δ, δθ )
        end
        # correct for the fact that we took an exponential of the random coefficients
        ExponentiationCorrection!( G, H, θ, dimθz( d ) )

    end

    # profile_count[1] += 1
    # Profile.take_heap_snapshot( "snapshot$(profile_count).heapsnapshot" )
    return F
end



