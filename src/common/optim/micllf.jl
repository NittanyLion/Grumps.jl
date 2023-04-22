function MicroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: GrumpsMicroNoData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired
    return F
end

@todo 1 "move sizes elsewhere"

function sizes( x )
    x == nothing ? nothing : size(x)
end


function sizes( F, G, H, δ )
    sizes(F), sizes(G), sizes(H), sizes(δ)
end

@todo 1 "document micllf"
@todo 2 "parallelize MicroObjectiveθ!"

function MicroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: MicroData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    weights, consumers, products, insides, parameters = RSJ( d )

    computeF, computeG, computeH = computewhich( F, G, H )

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired
    length( consumers ) == 0 && return F

    ChoiceProbabilities!( s, d, o, δ )                                             # fill s with some goodies

    if computeF
        F -= sum( log( s.πi[i] ) for i ∈ consumers )                        # compute objective function
    end

    computeG || computeH || return F                                                # return if G,H are not needed

    # now compute the gradient and/or Hessian
    Σππ = ComputeΣππ( s, d, o )

    if computeG 
        @inbounds for k ∈ insides
            G[k] -= sum( d.Y[i,k] - Σππ[i,k] / s.πi[i] for i ∈ consumers ) 
        end           
    end

    computeH || return F

    # now compute the Hessian
    @threads :dynamic for t ∈ insides
        H[t,t] += sum( Σππ[i,t] / s.πi[i] for i ∈ consumers )
        for k ∈ 1:t
            for i ∈ consumers
                H[k,t] += Σππ[i,k] * Σππ[i,t] / s.πi[i]^2 - 
                            2.0 * sum( d.w[r] * s.πri[r,i] * s.πrij[r,i,k] * s.πrij[r,i,t] for r ∈ weights )  / s.πi[i] 
            end
        end
    end

    Symmetrize!( H )
    return F
end


function MicroObjectiveθ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T},
    θ           :: A1{T},
    δ           :: A1{T},
    d           :: GrumpsMicroNoData{T}, 
    s           :: GrumpsMicroNoSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    F = SetZero!( setzero, F, G, Hθθ, Hδθ )                                       # set F,G,H to zero if so desired
    return F
end
  

function MicroObjectiveθ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T}, 
    θ           :: A1{T}, 
    δ           :: A1{T},
    d           :: MicroData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions, 
    setzero     :: Bool = true 
    ) where {T<:Flt}

    weights, consumers, products, insides, parameters = RSJ( d )
    dθz = dimθz( d );  dθ = dimθ( d )
    J = products[end]

    computeF, computeG, computeHθθ, computeHδθ = computewhich( F, G, Hθθ, Hδθ )
    computeH = computeHθθ || computeHδθ

    F = SetZero!( setzero, F, G, Hθθ, Hδθ  ) 

    ChoiceProbabilities!( s, d, o, δ )    # only recomputed if δ is different from before or has not yet been computed
                                


    computeF && ( F -= sum( log( s.πi[i] ) for i ∈ consumers  ) )       # compute F if so desired
    if !( computeG || computeH ) 
        return F                      
    end

    Σπb = zeros( T, dθ )
    Δb =  zeros( T, J, dθ )

    for i ∈ consumers                                   
        Σπb .= zeros( T )
        for r ∈ weights                             
            ComputeΔb!( Δb, s, d, o, r, i )
            for t ∈ parameters        
                Σπb[t] += d.w[r] * s.πri[r,i] * Δb[d.y[i],t] 
                # now compute things specifically for the Hessian; more to be computed at the end
                if computeHθθ 
                    for k ∈ 1:t  
                        Hθθ[k,t] +=  sum( d.w[r] * ( s.πri[r,i] - d.Y[i,j] ) * s.πrij[r,i,j] * Δb[j,k] * Δb[j,t] for j ∈ products ) / s.πi[i] 
                    end 
                end
                if computeHδθ 
                    for k ∈ insides  
                        Hδθ[k,t] += d.w[r] * s.πri[r,i] * s.πrij[r,i,k] *  ( Δb[d.y[i],t] + Δb[k,t] ) / s.πi[i] 
                    end
                end
            end
        end
        if computeG 
            for k ∈ parameters 
                G[k] -= Σπb[k] / s.πi[i]  
            end 
        end
        if computeHθθ 
            for t ∈ parameters, k ∈ 1:t  
                Hθθ[k,t] += Σπb[k] * Σπb[t] / s.πi[i]^2 
            end 
        end
        if computeHδθ 
            for t ∈ parameters, k ∈ insides
                Hδθ[k,t] -= sum( d.w[r] * s.πri[r,i] * s.πrij[r,i,k] * Σπb[t] / s.πi[i]^2 for r ∈ weights ) 
            end 
        end
    end


    if computeHθθ 
        Symmetrize!( Hθθ )
    end

    return F
end    

