# These are just basic support functions



function ChoiceProbabilities!( π::Matrix{T}, Aθ::Matrix{T}, δ::Vector{T} ) where {T<:Flt}
    for r ∈ axes( π, 1)
        for j ∈ axes(π,2)  π[r,j] = Aθ[r,j] + δ[j] end
        softmax!( @view π[r,:] )
    end
end

function ChoiceProbabilities!( π::Array{T,3}, ZXθ::Array{T,3}, δ::Vector{T} ) where {T<:Flt}
    for i ∈ axes( π, 2)
        for r ∈ axes( π, 1)
            for j ∈ axes(π,3)  π[r,i,j] = ZXθ[r,i,j] + δ[j] end
            softmax!( @view π[r,i,:] )
        end
    end
end


function WeightedSum!( b::Vector{T}, w::Vector{T}, A::Matrix{T} ) where {T<:Flt}
    for j ∈ axes(b,1)
        b[j] = sum( w[r] * A[r,j] for r ∈ 1:length(w) )
    end
    b
end

function WeightedSum!( B::Matrix{T}, w::Vector{T}, A::Matrix{T}, C::Matrix{T} ) where {T<:Flt}
    for j ∈ axes(B,2)
        for i ∈ axes(B,1)
            B[i,j] = sum( w[r] * A[r,i] * C[r,j] for r ∈ 1:length(w) )
        end
    end
    B
end

function WeightedSum!( B::Matrix{T}, w::Vector{T}, A::Matrix{T}, C::Array{T,3} ) where {T<:Flt}
    for j ∈ axes(B,2)
        for i ∈ axes(B,1)
            B[i,j] = sum( w[r] * A[r,i] * C[r,i,j] for r ∈ 1:length(w) )
        end
    end
    B
end


function Symmetrize!(A::Matrix)
    for ind ∈ CartesianIndices( A )
        (k,t) = Tuple( ind )
        k > t && ( A[ind] = A[t,k] )
    end
end




function Computeπri!( πri::Matrix{T}, πrij::Array{T,3}, y::Vector{Int} ) where {T<:Flt}
    for i ∈ 1:size(πri,2)
        for r ∈ 1:size(πri,1)
           πri[r,i] = πrij[r,i,y[i]] 
        end
    end
    πri
end





function WeightedDifference!( Δ::Array{T,3}, A::Array{T,3}, π::Matrix{T} ) where {T<:Flt}
    for k ∈ axes( Δ,3 )
        for r ∈ axes( Δ, 1 )
            sm = sum( π[r,t] * A[r,t,k] for t ∈ axes(A,2) )
            for j ∈ axes( Δ, 2 )
               Δ[r,j,k] = A[r,j,k] - sm
            end
        end
    end
end


# weighted sum over second index
function WeightedSum2!( C::Vector{T}, w::Vector{T}, A::Matrix{T} ) where {T<:Flt}
    for i ∈ axes(C, 1)
        C[i] = sum( w[j] * A[i,j] for j ∈ axes(A,2) )
    end
end


function ComputeΔ!( Δ::Array{T,3}, π::Matrix{T} ) where {T<:Flt}
    for k ∈ axes(Δ,3), j ∈ axes(Δ,2), r ∈ axes(Δ,1)
        Δ[r,j,k] = (j==k) - π[r,k]
    end
    Δ
end

