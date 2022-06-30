


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

    softmaxδ = softmax( vcat( δ, zero( T ) ) )
    s.πi .= zero( T )
    @threads :dynamic for i ∈ consumers
        for r ∈ weights 
            for j ∈ eachindex( softmaxδ )
                s.πrij[r,i,j] = s.ZXθ[r,i,j] * softmaxδ[j] 
            end
            SumNormalize!( @view s.πrij[ r, i, : ] )
            s.πri[r,i] = s.πrij[ r,i, d.y[i] ]
        end
        s.πi[i] = sum( d.w[r] * s.πri[r,i] for r ∈ weights )
    end
    return nothing
end





# function ChoiceProbabilities!( π::AA2{T}, Aθ::AA2{T}, δ::AA1{T}, nth :: Int, ::Val{:fast} ) where {T<:Flt}
#     softmaxδ = softmax( vcat( δ, zero( T ) ) )
#     for r ∈ axes( π, 1)
#         for j ∈ axes(π,2)  
#             π[r,j] = Aθ[r,j] * softmaxδ[j] 
#         end                          
#         SumNormalize!( @view π[r,:] )
#     end
#     return nothing
# end



function ChoiceProbabilities!( 
    s       :: MacroSpace{T}, 
    d       :: GrumpsMacroData{T}, 
    o       :: OptimizationOptions, 
    δ       :: Vec{T}
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
        s.πj[j] = sum( d.w[r] * s.πrj[r,j] for r ∈ weights )
        s.ρ[j] = d.N * d.s[j] / s.πj[j]
    end
    for r ∈ weights
        s.ρπ[r] = sum( s.ρ[j] * s.πrj[r,j] for j ∈ products )
    end

    return nothing
end

