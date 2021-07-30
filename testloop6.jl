using BenchmarkTools, LoopVectorization

import Base.Threads.@threads 


const n = 2
const N = 10_000

A = zeros(n,n)
B = randn(n)
C = randn(n,n)
D = randn(n)
E = randn(N)
F = randn(N)
G = randn(N,n)
H = randn(N,n,n)


function f1( A::Matrix{T}, B::Vector{T}, C::Matrix{T}, D::Vector{T}, E::Vector{T}, F::Vector{T}, G::Matrix{T}, H::Array{T,3} ) where {T<:AbstractFloat}
    @threads for ind ∈ CartesianIndices( A )
        (k,t) = Tuple( ind )
        k > t && continue
        for j ∈ axes(G,2)
            A[k,t] += B[j] * C[j,k] * C[j,t] / D[j]  + sum( E[r] * ( F[r] - B[j] ) * G[r,j] * H[r,j,k] * H[r,j,t] for r ∈ axes(E,1) )
        end
    end
    A
end

function f2( A::Matrix{T}, B::Vector{T}, C::Matrix{T}, D::Vector{T}, E::Vector{T}, F::Vector{T}, G::Matrix{T}, H::Array{T,3} ) where {T<:AbstractFloat}
    @threads for t ∈ axes(A,2)
        for k ∈ 1:t
            for j ∈ axes(G,2)
                A[k,t] += B[j] * C[j,k] * C[j,t] / D[j]  + sum( E[r] * ( F[r] - B[j] ) * G[r,j] * H[r,j,k] * H[r,j,t] for r ∈ axes(E,1) )
            end
        end
    end
    A
end

display(f1(A,B,C,D,E,F,G,H)[1:2,1:2]); println()
@btime f2($A, $B, $C, $D, $E, $F, $G, $H )
A .= 0.0
display(f2(A,B,C,D,E,F,G,H)[1:2,1:2]); println()
@btime f2($A, $B, $C, $D, $E, $F, $G, $H )
