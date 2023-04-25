function MacroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: GrumpsMacroNoData{T}, 
    s           :: MacroSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired
    return F
end



function MacroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: MacroData{T}, 
    s           :: MacroSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    weights, products, insides, parameters = RJ( d )

    computeF, computeG, computeH = computewhich( F, G, H )

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired

    ChoiceProbabilities!( s, d, o, δ )                                             # fill s with some goodies

    if computeF
        # ************* TAKE THIS OUT!
        for j ∈ products
            if s.πj[j] < 0.0 
                @info "negative choice probability $j"
            end
            if d.s[j] < 0.0
                @info "negative shares $j"
            end
        end
        # *********** TAKE THIS OUT!
        F -= d.N * sum( iszero( d.s[j] ) ? d.s[j] : d.s[j] * log( s.πj[j] / d.s[j] ) for j ∈ products )                        # compute objective function
    end


    computeG || computeH || return F                                                # return if G,H are not needed

    # now compute the gradient and/or Hessian
    Σππ = ComputeΣππ( s, d, o )


    if computeG 
        @inbounds for k ∈ insides
            G[k] -=  ( d.N * d.s[k] - sum( s.ρ[j] * Σππ[j,k] for j ∈ products ) )
        end           
    end

    if computeH

        # now compute the Hessian
        @threads :dynamic for t ∈ insides
            H[t,t] += sum(  d.w[r] * s.ρπ[r] * s.πrj[r,t]  for r ∈ weights )
            for k ∈ 1:t
                H[k,t] += sum( s.ρ[j] * Σππ[j,k] * Σππ[j,t]  / s.πj[j] for j ∈ products ) 
                H[k,t] -= 2.0 * sum( d.w[r] * s.ρπ[r] * s.πrj[r,k] * s.πrj[r,t] for r ∈ weights )
            end
        end

        Symmetrize!( H )
    end

    return F
end

function MacroObjectiveθ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T},
    θ           :: AA1{T},
    δ           :: AA1{T},
    d           :: GrumpsMacroNoData, 
    s           :: MacroSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    F = SetZero!( setzero, F, G, Hθθ, Hδθ )                                       # set F,G,H to zero if so desired
    return F
end
  
@todo 2 "parallelize MacroObjectiveθ!"

function MacroObjectiveθ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T}, 
    θ           :: A1{T}, 
    δ           :: A1{T},
    d           :: MacroData{T}, 
    s           :: MacroSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    weights, products, insides, parameters, = RJ( d )
    J = products[end]
    dθ = parameters[end]

    ChoiceProbabilities!( s, d, o, δ )                                             

    computeF, computeG, computeHθθ, computeHδθ = computewhich( F, G, Hθθ, Hδθ )
    computeH = computeHθθ || computeHδθ

    F = SetZero!( setzero, F, G, Hθθ, Hδθ  ) 

    if computeF 
        F -= d.N * sum( iszero( d.s[j] ) ? d.s[j] : d.s[j] * log( s.πj[j] / d.s[j] ) for j ∈ products )        # compute F if so desired
    end
    
    computeG || computeH || return F                       # return if G and H are not needed

    # ΣπΔ :: Matrix{T}
    # if computeHδθ
    Jalloc = J * computeHδθ
    Δ =  zeros( T, Jalloc, Jalloc )
    ΣπΔ = zeros( T, Jalloc, Jalloc )
    # end

    ΣπA = zeros( T, J, dθ )
    Δa  = zeros( T, J, dθ )

    for r ∈ weights
        ComputeΔa!( Δa, s, d, o, r )
        for j ∈ products, k ∈ parameters
            ΣπA[j,k] += d.w[r] * s.πrj[r,j] * Δa[j,k]
            # printstyled( "$j $k  $(d.w[r]) $(s.πrj[r,k]) $(Δa[j,k])\n"; color = :blue )
        end 
        if computeHθθ
            for t ∈ parameters, k ∈ 1:t 
                Hθθ[k,t] += d.w[r] * sum( ( s.ρπ[r] - s.ρ[j] ) * s.πrj[r,j] * Δa[j,k] * Δa[j,t] for j ∈ products )
            end
        end
        if computeHδθ
            for j ∈ products, k ∈ products
                Δ[j,k] = ( j == k ) - s.πrj[r,k]
            end
            for t ∈ parameters, k ∈ insides
                Hδθ[k,t] += sum( d.w[r] * s.πrj[r,j] * ( s.ρπ[r] - s.ρ[j] ) * Δ[j,k] * Δa[j,t] for j ∈ products )
            end 
            for j ∈ products, k ∈ products
                ΣπΔ[j,k] += d.w[r] * s.πrj[r,j] * Δ[j,k]
            end
        end
    end        
    
    if computeG
        for k ∈ parameters
            G[k] -= sum( s.ρ[j] * ΣπA[j,k] for j ∈ products )
        end
    end

    if computeHθθ
        for t ∈ parameters, k ∈ 1:t 
            Hθθ[k,t] += sum( s.ρ[j] * ΣπA[j,k] * ΣπA[j,t] / s.πj[j] for j ∈ products )
        end
        Symmetrize!( Hθθ )
    end


    if computeHδθ
        for t ∈ parameters, k ∈ insides
            Hδθ[k,t] += sum( ΣπΔ[j,k] *  s.ρ[j]  * ΣπA[j,t] / s.πj[j] for j ∈ products )
        end
    end

    return F
end    

