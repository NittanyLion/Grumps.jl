

# """
#     ChoiceProbabilities!( π :: AA3{T}, ZXθ :: AA3{T}, δ :: Vec{T}, ::Val{:fast}, nthr :: Int = 1 )

#     Computes micro choice probabilities; this is the fast version.
# """
# function ChoiceProbabilities!( π :: AA3{T}, ZXθ :: AA3{T}, δ :: Vec{T}, ::Val{:fast}, nthr :: Int = 1 ) where {T<:Flt}
#     softmaxδ = softmax( δ )                                                 
#     @grumpsthreads nthr for i ∈ CartesianIndices( axes( π, 1 ), axes( π, 2) )
#         for j ∈ eachindex( softmaxδ )                                      # loop over products
#             π[i,j] = ZXθ[i,j] * softmaxδ[j]                         # ZXθ already contains softmaxes in this scheme
#         end
#         SumNormalize!( @view π[i,:] )                                 # make probabilities sum to one
#     end
#     return nothing
# end


# """
#     ChoiceProbabilities!( π :: AA3{T}, ZXθ :: AA3{T}, δ :: Vec{T}, ::Val{:robust}, nthr :: Int = 1 )

#     Computes micro choice probabilities; this is the robust version.
# """
# function ChoiceProbabilities!( π :: AA3{T}, ZXθ :: AA3{T}, δ :: Vec{T}, ::Val{:robust}, nthr :: Int = 1 ) where {T<:Flt}
#     @grumpsthreads nthr for i ∈ CartesianIndices( axes( π, 1 ), axes( π, 2) )
#         for j ∈ axes(π,3)  
#             π[i,j] = ZXθ[i,j] + δ[j] 
#         end
#         softmax!( @view π[i,:] )                                      # exp(.) / sum exp(.)
#     end
#     return nothing
# end



# function Computeπri!( πri :: AA2{T}, πrij :: AA3{T}, y :: AbstractVector{ Int }, nth :: Int = 1 ) where {T<:Flt}
#     @grumpsthreads nth for ri ∈ CartesianIndices( axes( πri, 1 ), axes( πri, 2) )
#         πri[ri] = πrij[ ri, y[ ri[2] ] ]
#     end
#     return nothing
# end


# function WeightedSum!( b :: AA1{T}, w :: AA1{T}, A :: AA2{T}, nth :: Int = 1 ) where {T<:Flt}
#     @grumpsthreads nth for j ∈ eachindex( b )
#         @inbounds        b[j] = sum( w[r] * A[r,j] for r ∈ eachindex( w ) )
#     end
#     return nothing
# end


# function WeightedSum!( B :: AA2{T}, w :: AA1{T}, A :: AA2{T}, C :: AA2{T}, nth :: Int = 1 ) where {T<:Flt}
#     @grumpsthreads nth for i ∈ CartesianIndices( ( axes(B,1), axes(B,2) ) )
# @inbounds            B[i] = sum( w[r] * A[r,i[1]] * C[r,i[2]] for r ∈ eachindex(w) )
#     end
#     B
# end

# function MicroChoiceProbabilitiesδ!( s :: GrumpsMicroSpace{T}, d :: GrumpsMicroData{T}, o :: OptimizationOptions, δ :: AA1{T} ) where {T<:Flt}
#     nth = inthreads( o )
#     ChoiceProbabilities!( s.πrij, s.ZXθ, δ, Val( probtype( o ) ), nth )
#     Computeπri!( s.πri, s.πrij, d.y, nth )
#     WeightedSum!( s.πi, d.w, s.πri, nth )
#     return nothing
# end
