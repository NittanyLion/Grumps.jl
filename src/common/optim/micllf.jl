function MicroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: GrumpsMicroNoData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions,
    m           :: Int, 
    setzero     :: Bool = true 
    ) :: Union{Nothing, T} where {T<:Flt}

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired
    return F
end


@todo 2 "parallelize MicroObjectiveθ!"



FunctionValue( πi :: Vec{T}, consumers, ::Val{:micδ}, ::Val{ :Grumps } ) where {T<:Flt} = sum( log( πi[i] ) for i ∈ consumers ) 


function updateGradient!( G :: Vec{T}, Σππ :: Mat{T}, πi :: Vec{T}, Y :: Mat{Bool}, consumers, insides, ::Val{:micδ}, ::Val{ :Grumps } ) where {T<:Flt}
    @inbounds for k ∈ insides
        G[k] -= sum( Y[i,k] - Σππ[i,k] / πi[i] for i ∈ consumers ) 
    end 
    nothing
end




function updateHessian!( H :: Mat{T}, Σππ :: Mat{T}, πi :: Vec{T}, πri :: Mat{T},  πrij :: A3{T}, w :: Vec{T}, weights, consumers, insides, ::Val{:micδ}, ::Val{ :Grumps }, loopvectorization :: Val{ false }  ) :: Nothing where {T<:Flt}
    @threads :dynamic for t ∈ insides
        H[t,t] += sum( Σππ[i,t] / πi[i] for i ∈ consumers )
        for k ∈ 1:t
            for i ∈ consumers
                H[k,t] += Σππ[i,k] * Σππ[i,t] / πi[i]^2 - 
                            2.0 * sum( w[r] * πri[r,i] * πrij[r,i,k] * πrij[r,i,t] for r ∈ weights )  / πi[i] 
            end
        end
    end
    Symmetrize!( H )
    return nothing
end



function updateHessian!( H :: Mat{T}, Σππ :: Mat{T}, πi :: Vec{T}, πri :: Mat{T},  πrij :: A3{T}, w :: Vec{T}, weights, consumers, insides, ::Val{:micδ}, ::Val{ :Grumps }, loopvectorization :: Val{ true }  ) :: Nothing where {T<:Flt}
    @tullio fastmath=false H[t,t] += Σππ[i,t+0] / πi[i] 
    @tullio fastmath=false H[k,t] += Σππ[i,k+0] * Σππ[i,t+0] / πi[i]^2
    @tullio fastmath=false H[k,t] += - 2.0 * w[r] * πri[r,i] * πrij[r,i,k+0] * πrij[r,i,t+0] / πi[i]
    return nothing
end


function updateHessian!( H :: Mat{T}, Σππ :: Mat{T}, πi :: Vec{T}, πri :: Mat{T},  πrij :: A3{T}, w :: Vec{T}, weights, consumers, insides, ::Val{:micδ}, ::Val{ :Grumps }, o  ) :: Nothing where {T<:Flt}
    return updateHessian!( H :: Mat{T}, Σππ :: Mat{T}, πi :: Vec{T}, πri :: Mat{T},  πrij :: A3{T}, w :: Vec{T}, weights, consumers, insides, Val(:micδ), Val( :Grumps ), Val( o.loopvectorization )  ) 
end

  

function MicroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: MicroData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions, 
    m           :: Int,
    setzero     :: Bool = true 
    ) :: Union{T,Nothing} where {T<:Flt}

    weights, consumers, products, insides, parameters = RSJ( d )

    computeF, computeG, computeH = computewhich( F, G, H )

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired
    length( consumers ) == 0 && return F

    ChoiceProbabilities!( s, d, o, δ )                                             # fill s with some goodies

    if computeF
        F -= FunctionValue( πi( s ), consumers, Val( :micδ), Val( :Grumps )  )
    end

    computeG || computeH || return F                                                # return if G,H are not needed

    # now compute the gradient and/or Hessian
    Σππ = ComputeΣππ( s, d, o )

    computeG && updateGradient!( G, Σππ, πi( s ), Y( d ),  consumers, insides, Val( :micδ ), Val( :Grumps ) )

    # now compute the Hessian
    computeH && updateHessian!( H, Σππ, πi( s ), πri( s ), πrij( s ), w( d ), weights, consumers, insides, Val( :micδ ), Val( :Grumps ), o  )

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
    m           :: Int,
    setzero     :: Bool = true 
    ) :: Union{T,Nothing} where {T<:Flt}

    F = SetZero!( setzero, F, G, Hθθ, Hδθ )                                       # set F,G,H to zero if so desired
    return F
end
  


function GradientHessianMicroθ!( 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T}, 
    d           :: MicroData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions, 
    loopvectorization :: Val{ true }
    ) :: Nothing where {T<:Flt}
    
    computeF, computeG, computeHθθ, computeHδθ = computewhich( nothing, G, Hθθ, Hδθ )

    weights, consumers, products, insides, parameters = RSJ( d )
    dθz = dimθz( d );  dθ = dimθ( d );  J = dimJ( d )

    Σπb = zeros( T, dθ )
    Δb =  zeros( T, J, dθ )

    for i ∈ consumers                                   
        Σπb .= zero( T )
        for r ∈ weights                             
            ComputeΔb!( Δb, s, d, o, r, i )
            yi = d.y[i]
            @tullio fastmath=false Σπb[t] += d.w[$r] * s.πri[$r,$i] * Δb[$yi,t]
            if computeHθθ
                @tullio fastmath=false Hθθ[k,t] +=  d.w[$r] * ( s.πri[$r,$i] - d.Y[$i,j] ) * s.πrij[$r,$i,j] * Δb[j,k+0] * Δb[j,t+0] / s.πi[$i] 
            end
            if computeHδθ 
                @tullio fastmath=false Hδθ[k,t] += d.w[$r] * s.πri[$r,$i] * s.πrij[$r,$i,k+0] *  ( Δb[$yi,t+0] + Δb[k,t] ) / s.πi[$i] 
            end
        end
        if computeG 
            @tullio fastmath=false G[k] += - Σπb[k+0] / s.πi[$i]  
        end
        if computeHθθ 
            @tullio fastmath=false Hθθ[k,t] += Σπb[k+0] * Σπb[t+0] / s.πi[$i]^2 
        end
        if computeHδθ 
            @tullio fastmath=false Hδθ[k,t] += - d.w[r] * s.πri[r,$i] * s.πrij[r,$i,k+0] * Σπb[t+0] / s.πi[$i]^2 
        end
    end

    return nothing
end

function GradientHessianMicroθ!( 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T}, 
    d           :: MicroData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions, 
    loopvectorization :: Val{ false }
    ) :: Nothing where {T<:Flt}

    computeF, computeG, computeHθθ, computeHδθ = computewhich( nothing, G, Hθθ, Hδθ )

    weights, consumers, products, insides, parameters = RSJ( d )
    dθz = dimθz( d );  dθ = dimθ( d );  J = dimJ( d )


    Σπb = zeros( T, dθ )
    Δb =  zeros( T, J, dθ )

    for i ∈ consumers                                   
        Σπb .= zero( T )
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

    return nothing
end

function GradientHessianMicroθ!( 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T}, 
    d           :: MicroData{T}, 
    s           :: MicroSpace{T},
    o           :: OptimizationOptions 
    ) :: Nothing where {T<:Flt} 
    
    return GradientHessianMicroθ!( G, Hθθ, Hδθ, d, s, o, Val( o.loopvectorization ) )
    # return GradientHessianMicroθ!( G, Hθθ, Hδθ, d, s, o, Val( false) ) 
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
    m           :: Int,
    setzero     :: Bool = true 
    ) :: Union{Nothing, T} where {T<:Flt}

    weights, consumers, products, insides, parameters = RSJ( d )
    # dθz = dimθz( d );  dθ = dimθ( d )
    J = products[end]

    computeF, computeG, computeHθθ, computeHδθ = computewhich( F, G, Hθθ, Hδθ )
    computeH = computeHθθ || computeHδθ

    F = SetZero!( setzero, F, G, Hθθ, Hδθ  ) 
    length( consumers ) == 0 && return F     # if there are no consumers then there is nothing to compute

    ChoiceProbabilities!( s, d, o, δ )    # only recomputed if δ is different from before or has not yet been computed
                                


    computeF && ( F -= sum( log( s.πi[i] ) for i ∈ consumers  ) )       # compute F if so desired
    if !( computeG || computeH ) 
        return F                      
    end

    GradientHessianMicroθ!( G, Hθθ, Hδθ, d, s, o )

 

    return F
end    

