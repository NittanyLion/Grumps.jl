


"""
    SumNormalize!( x :: AbstractVector{T} ) 
   
computes x / sum( x ) and stores it in x
"""
function SumNormalize!( x :: AbstractVector{T} ) where {T<:Flt} 
    sm = sum( x )
    for j ∈ eachindex( x )
        x[j] /= sm
    end
    return nothing
end



function ChoiceProbabilities!( πrij :: A3{T}, πri :: A2{T}, πi :: A1{T}, ZXθ :: A3{T}, y :: A1{Int}, w :: A1{T}, δ :: A1{T}, o :: OptimizationOptions, consumers, products, weights, ::Val{ :miccp }, ::Val{ :Grumps } ) where {T<:Flt}
    softmaxδ = softmax( vcat( δ, zero( T ) ) )
    πi .= zero( T )
    @threads :dynamic for i ∈ consumers
        for r ∈ weights 
            for j ∈ products
                πrij[r,i,j] = ZXθ[r,i,j] * softmaxδ[j] 
            end
            SumNormalize!( @view πrij[ r, i, : ] )
            πri[r,i] = πrij[ r,i, y[i] ]
        end
        πi[i] = sum( w[r] * πri[r,i] for r ∈ weights )
    end
    nothing
end



"""
    ChoiceProbabilities!( s :: MicroSpace{T}, d :: GrumpsMicroData{T}, o :: OptimizationOptions, δ :: Vec{T} )

Computes various micro choice probabilities and their aggregates
"""
function ChoiceProbabilities!( 
    s       :: MicroSpace{T}, 
    d       :: GrumpsMicroData{T}, 
    o       :: OptimizationOptions, 
    δ       :: Vec{T}
    ) where {T<:Flt}

    weights, consumers, products, insides, = RSJ( d )
    ChoiceProbabilities!( πrij(s), πri(s), πi(s), ZXθ(s), y(d), w(d), δ, o, consumers, products, weights, Val( :miccp ), Val( :Grumps ) )
    return nothing
end






function ChoiceProbabilities!( 
    s       :: MacroSpace{T}, 
    d       :: GrumpsMacroData{T}, 
    o       :: OptimizationOptions, 
    δ       :: Vec{T},
    loopvectorization :: Val{true}
    ) where {T<:Flt}

    weights, products, insides, = RJ( d )
    softmaxδ = softmax( vcat( δ, zero( T ) ) )  

    @tullio fastmath=false s.πrj[r,j] = s.Aθ[r,j] * softmaxδ[j]
   
    for r ∈ weights
        SumNormalize!( @view s.πrj[r,:] )
    end


    @tullio fastmath=false s.πj[j] = d.w[r] * s.πrj[r,j]
    
    s.ρ .= d.N * d.s ./ s.πj


    @tullio fastmath=false s.ρπ[r] = s.ρ[j] * s.πrj[r,j] 
    return nothing        
end


function ChoiceProbabilities!( 
    s       :: MacroSpace{T}, 
    d       :: GrumpsMacroData{T}, 
    o       :: OptimizationOptions, 
    δ       :: Vec{T},
    loopvectorization :: Val{false}
    ) where {T<:Flt}

    # if s.lastδ == δ && !s.mustrecompute
    #     return nothing
    # end
    # copyto!( s.lastδ, δ )

    weights, products, insides, = RJ( d )

    softmaxδ = softmax( vcat( δ, zero( T ) ) )
    @threads :dynamic for r ∈ weights
        for j ∈ products
            s.πrj[r,j] = s.Aθ[r,j] * softmaxδ[j] 
        end                          
        SumNormalize!( @view s.πrj[r,:] )
    end

    @threads :dynamic for j ∈ products
        s.πj[j] = zero( T )
        for r ∈ weights
            s.πj[j] += d.w[r] * s.πrj[r,j] 
        end
    end

    for j ∈ eachindex( s.ρ )
        s.ρ[j] = d.N * d.s[j] / s.πj[j]
    end

    
    for r ∈ weights
        s.ρπ[r] = sum( s.ρ[j] * s.πrj[r,j] for j ∈ products )
    end


    return nothing
end



function ChoiceProbabilities!( 
    s       :: MacroSpace{T}, 
    d       :: GrumpsMacroData{T}, 
    o       :: OptimizationOptions, 
    δ       :: Vec{T}
    ) where {T<:Flt}


    return ChoiceProbabilities!( s, d, o, δ, Val( o.loopvectorization ) )
end

