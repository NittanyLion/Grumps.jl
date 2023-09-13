function MacroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: GrumpsMacroNoData{T}, 
    s           :: MacroSpace{T},
    o           :: OptimizationOptions, 
                :: Int,
    setzero     :: Bool = true 
    ) :: Union{Nothing,T} where {T<:Flt} 

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired
    return F
end



function MacHessianδ!( H :: Matrix{T}, d :: GrumpsMacroData{T}, s :: GrumpsMacroSpace{T}, Σππ :: Matrix{T}, loopvectorization :: Val{ false } ) :: Nothing where {T<:Flt}
    weights, products, insides, parameters = RJ( d )
    @threads :dynamic for t ∈ insides
        H[t,t] += sum(  d.w[r] * s.ρπ[r] * s.πrj[r,t]  for r ∈ weights )
        for k ∈ 1:t
            H[k,t] += sum( s.ρ[j] * Σππ[j,k] * Σππ[j,t]  / s.πj[j] for j ∈ products ) 
            H[k,t] -= 2.0 * sum( d.w[r] * s.ρπ[r] * s.πrj[r,k] * s.πrj[r,t] for r ∈ weights )
        end
    end
    Symmetrize!( H )
    return nothing
end

function MacHessianδ!( H :: Matrix{T}, d :: GrumpsMacroData{T}, s :: GrumpsMacroSpace{T}, Σππ :: Matrix{T}, loopvectorization :: Val{ true } ) :: Nothing where {T<:Flt}
    @tullio fastmath=false H[t,t] += d.w[r] * s.ρπ[r] * s.πrj[r,t+0] 
    @tullio fastmath=false H[k,t] += - 2.0 * d.w[r] * s.ρπ[r] * s.πrj[r,k+0] * s.πrj[r,t+0]
    @tullio fastmath=false H[k,t] += s.ρ[j] * Σππ[j,k] * Σππ[j,t]  / s.πj[j] 
    return nothing
end


MacHessianδ!( H, d, s, Σππ, o ) = MacHessianδ!( H, d, s, Σππ, Val( o.loopvectorization) )

function MacroObjectiveδ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    H           :: HType{T}, 
    δ           :: AA1{T},
    d           :: GrumpsMacroData{T}, 
    s           :: GrumpsMacroSpace{T},
    o           :: OptimizationOptions, 
    m           :: Int, 
    setzero     :: Bool = true 
    ) :: Union{Nothing,T} where {T<:Flt} 

    weights, products, insides, parameters = RJ( d )

    computeF, computeG, computeH = computewhich( F, G, H )

    F = SetZero!( setzero, F, G, H, nothing )                                       # set F,G,H to zero if so desired

    ChoiceProbabilities!( s, d, o, δ )                                             # fill s with some goodies

    if computeF
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
        MacHessianδ!( H, d, s, Σππ, o )
    end

    return F
end


# checksum( x :: Nothing ) = nothing
# checksum( x ) = sum( x.* x ) / length( x )

# macro printchecksum( u, x )
#     local valu = esc(u)
#     local val = esc(x)
#     s = string( x )
#     return :( println( $s, " ", checksum( $val ), "  ", $valu ) )
# end



# function UpdateGradientHessian!( 
#     G           :: GType{T},
#     Hθθ         :: HType{T}, 
#     Hδθ         :: HType{T},
#     d           :: GrumpsMacroData{T},
#     s           :: MacroSpace{T},
#     o           :: OptimizationOptions,
#     loopvectorization :: Val{ true } ) :: Nothing where {T<:Flt}

#     computeF, computeG, computeHθθ, computeHδθ = computewhich( nothing, G, Hθθ, Hδθ )
#     weights, products, insides, parameters = RJ( d )
#     J = products[end]
#     dθ = parameters[end]
#     R = weights[end]

#     avg = zeros( R, dθ )
#     Δa = zeros( R, J, dθ )
#     @tullio fastmath=false avg[r,k] = s.πrj[r,j] * d.𝒳[j,k]
#     @tullio fastmath=false Δa[r,j,k] = d.𝒟[r,k] * ( d.𝒳[j,k] - avg[r,k] )

#     # Δa = ComputeΔa( s, d, o )
#     @tullio fastmath=false ΣπA[j,k] := d.w[r] * s.πrj[r,j] * Δa[r,j,k]
#     if computeHθθ
#         @tullio fastmath=false Hθθ[k,t] += d.w[r] * ( s.ρπ[r] - s.ρ[j] ) * s.πrj[r,j] * Δa[r,j,k+0] * Δa[r,j,t+0] 
#         @tullio fastmath=false Hθθ[k,t] += s.ρ[j] * ΣπA[j,k+0] * ΣπA[j,t+0] / s.πj[j] 
#     end
#     if computeHδθ
#         Δ = zeros( T, weights[end], products[end], products[end] )
#         @tullio fastmath=false Δ[r,j,k] = (j==k) - s.πrj[r,k]
#         @tullio fastmath=false Hδθ[k,t] += d.w[r] * s.πrj[r,j] * ( s.ρπ[r] - s.ρ[j] ) * Δ[r,j,k+0] * Δa[r,j,t]
#         @tullio fastmath=false ΣπΔ[j,k] := d.w[r] * s.πrj[r,j] * Δ[r,j,k+0]
#         @tullio fastmath=false Hδθ[k,t] +=  ΣπΔ[j,k+0] *  s.ρ[j]  * ΣπA[j,t+0] / s.πj[j] 
#     end
#     if computeG
#         @tullio fastmath=false G[k] += - s.ρ[j] * ΣπA[j,k+0] 
#     end
#     return nothing
# end


function UpdateGradientHessian!( 
    G           :: GType{T},
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T},
    d           :: GrumpsMacroData{T},
    s           :: MacroSpace{T},
    o           :: OptimizationOptions,
    loopvectorization :: Val{ true } ) :: Nothing where {T<:Flt}

    computeF, computeG, computeHθθ, computeHδθ = computewhich( nothing, G, Hθθ, Hδθ )
    weights, products, insides, parameters = RJ( d )
    J = products[end]
    dθ = parameters[end]
    Jalloc = J * computeHδθ

    Δ =  zeros( T, Jalloc, Jalloc )
    ΣπΔ = zeros( T, Jalloc, Jalloc )

    ΣπA = zeros( T, J, dθ )
    Δa  = zeros( T, J, dθ )
     
    for r ∈ weights
        ComputeΔa!( Δa, s, d, o, r )
        @tullio fastmath=false ΣπA[j,k] += d.w[$r] * s.πrj[$r,j] * Δa[j,k]
        if computeHθθ
            @tullio fastmath=false Hθθ[k,t] += d.w[$r] * ( s.ρπ[$r] - s.ρ[j] ) * s.πrj[$r,j] * Δa[j,k+0] * Δa[j,t+0]
        end
        if computeHδθ
            for j ∈ products, k ∈ products
                Δ[j,k] = ( j == k ) - s.πrj[r,k]
            end
            @tullio fastmath=false Hδθ[k,t] += d.w[$r] * s.πrj[$r,j] * ( s.ρπ[$r] - s.ρ[j] ) * Δ[j,k+0] * Δa[j,t]
            @tullio fastmath=false ΣπΔ[j,k] += d.w[$r] * s.πrj[$r,j] * Δ[j+0,k+0]
        end
    end      

    if computeG
        @tullio fastmath=false G[k] += - s.ρ[j] * ΣπA[j,k+0]
    end

    if computeHθθ
        @tullio fastmath=false Hθθ[k,t] += s.ρ[j] * ΣπA[j,k+0] * ΣπA[j,t+0] / s.πj[j] 
    end


    if computeHδθ
        @tullio fastmath=false Hδθ[k,t] += ΣπΔ[j,k+0] *  s.ρ[j]  * ΣπA[j,t+0] / s.πj[j] 
    end


    return nothing 
end


function UpdateGradientHessian!( 
    G           :: GType{T},
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T},
    d           :: GrumpsMacroData{T},
    s           :: MacroSpace{T},
    o           :: OptimizationOptions,
    loopvectorization :: Val{ false } ) :: Nothing where {T<:Flt}

    computeF, computeG, computeHθθ, computeHδθ = computewhich( nothing, G, Hθθ, Hδθ )
    weights, products, insides, parameters = RJ( d )
    J = products[end]
    dθ = parameters[end]
    Jalloc = J * computeHδθ

    Δ =  zeros( T, Jalloc, Jalloc )
    ΣπΔ = zeros( T, Jalloc, Jalloc )

    ΣπA = zeros( T, J, dθ )
    Δa  = zeros( T, J, dθ )

    for r ∈ weights
        ComputeΔa!( Δa, s, d, o, r )
        for j ∈ products, k ∈ parameters
            ΣπA[j,k] += d.w[r] * s.πrj[r,j] * Δa[j,k]
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


    return nothing 
end



function UpdateGradientHessian!( 
    G           :: GType{T},
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T},
    d           :: GrumpsMacroData{T},
    s           :: MacroSpace{T},
    o           :: OptimizationOptions ) :: Nothing where {T<:Flt}


    return UpdateGradientHessian!( G, Hθθ, Hδθ, d, s, o, Val( o.loopvectorization ) )
end


function MacroObjectiveθ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T},
    θ           :: AA1{T},
    δ           :: AA1{T},
    d           :: GrumpsMacroNoData{T}, 
    s           :: GrumpsMacroNoSpace{T},
    o           :: OptimizationOptions, 
    m           :: Int,
    setzero     :: Bool = true 
    ) :: Union{Nothing, T} where {T<:Flt}

    F = SetZero!( setzero, F, G, Hθθ, Hδθ )                                       # set F,G,H to zero if so desired
    return F
end
  

function MacroObjectiveθ!( 
    F           :: FType{T}, 
    G           :: GType{T}, 
    Hθθ         :: HType{T}, 
    Hδθ         :: HType{T}, 
    θ           :: A1{T}, 
    δ           :: A1{T},
    d           :: GrumpsMacroData{T}, 
    s           :: GrumpsMacroSpace{T},
    o           :: OptimizationOptions, 
    m           :: Int, 
    setzero     :: Bool = true 
    ) :: Union{Nothing, T} where {T<:Flt}

    weights, products, insides, parameters, = RJ( d )

    ChoiceProbabilities!( s, d, o, δ )                                             

    computeF, computeG, computeHθθ, computeHδθ = computewhich( F, G, Hθθ, Hδθ )

    F = SetZero!( setzero, F, G, Hθθ, Hδθ  ) 

    if computeF 
        F -= d.N * sum( iszero( d.s[j] ) ? d.s[j] : d.s[j] * log( s.πj[j] / d.s[j] ) for j ∈ products )        # compute F if so desired
    end
    
    computeG || computeHθθ || computeHδθ || return F

    UpdateGradientHessian!( G, Hθθ, Hδθ, d, s, o )



    return F
end    

