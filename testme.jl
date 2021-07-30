using LoopVectorization

J = 10
R = 10_000
Ao = randn(J-1,J-1)
b = randn(J)
c = randn(R)
D = randn(R,J)
E = randn(J,J)
g = randn(J)
Flt = AbstractFloat

function f1(A::Matrix{T}, b::Vector{T}, c::Vector{T}, D::Matrix{T}, E::Matrix{T}, g::Vector{T}, J::Int, R::Int ) where {T<:Flt}
    for k ∈ 1:J-1
        for j ∈ 1:J
            for r ∈ 1:R
                A[k,k] = A[k,k] + b[j] * c[r] * D[r,j] * D[r,k] 
            end
        end
    end
    for k ∈ 1:J-1
        for t ∈ 1:J-1
            for j ∈ 1:J
                A[k,t] +=  b[j] * E[j,k] * E[j,t] / g[j]
            end
        end
    end
    for k ∈ 1:J-1
        for t ∈ 1:J-1
            for j ∈ 1:J 
                for r ∈ 1:R 
                    A[k,t] -= 2.0 * b[j] * c[r] * D[r,j] * D[r,k] * D[r,t] 
                end
            end
        end
    end
end

function f2(A::Matrix{T}, b::Vector{T}, c::Vector{T}, D::Matrix{T}, E::Matrix{T}, g::Vector{T}, J::Int, R::Int ) where {T<:Flt}
    for k ∈ 1:J-1
        for j ∈ 1:J
            for r ∈ 1:R
                A[k,k] += b[j] * c[r] * D[r,j] * D[r,k] 
            end
        end
    end
    for k ∈ 1:J-1
        for t ∈ 1:J-1
            for j ∈ 1:J
                A[k,t] += b[j] * E[j,k] * E[j,t] / g[j]
                for r ∈ 1:R 
                    A[k,t] -= 2.0 * b[j] * c[r] * D[r,j] * D[r,k] * D[r,t] 
                end
            end
        end
    end
end


function f3(A::Matrix{T}, b::Vector{T}, c::Vector{T}, D::Matrix{T}, E::Matrix{T}, g::Vector{T}, J::Int, R::Int ) where {T<:Flt}
    for k ∈ 1:J-1
        A[k,k] += sum( b[j] * c[r] * D[r,j] * D[r,k] for j ∈ 1:J, r ∈ 1:R )
        for t ∈ 1:J-1
            A[k,t] += sum( b[j] * E[j,k] * E[j,t] / g[j] for j ∈ 1:J )
            A[k,t] -= 2.0 * sum( b[j] * c[r] * D[r,j] * D[r,k] * D[r,t] for j ∈ 1:J, r ∈ 1:R )
        end
    end
end


function f4(A::Matrix{T}, b::Vector{T}, c::Vector{T}, D::Matrix{T}, E::Matrix{T}, g::Vector{T}, J::Int, R::Int ) where {T<:Flt}
    @turbo for k ∈ 1:J-1
        for j ∈ 1:J
            for r ∈ 1:R
                A[k,k] += b[j] * c[r] * D[r,j] * D[r,k] 
            end
        end
    end
    @turbo for k ∈ 1:J-1
        for t ∈ 1:J-1
            for j ∈ 1:J
                A[k,t] += b[j]  * E[j,k] * E[j,t] / g[j]
                for r ∈ 1:R 
                    A[k,t] -= 2.0 * b[j] * c[r] * D[r,j] * D[r,k] * D[r,t] 
                end
            end
        end
    end
end



A = copy(Ao)
println("\ncompletely expanded")
@time f1(A, b, c, D, E, g, J, R)
@time f1(A, b, c, D, E, g, J, R)
println(A)

A = copy(Ao)
println("\nsomewhat more compact")
@time f2(A, b, c, D, E, g, J, R)
@time f2(A, b, c, D, E, g, J, R)
println(A)

A = copy(Ao)
println("\ncomprehensions")
@time f3(A, b, c, D, E, g, J, R)
@time f3(A, b, c, D, E, g, J, R)
println(A)

A = copy(Ao)
println("\nloopvectorization")
@time f4(A, b, c, D, E, g, J, R)
@time f4(A, b, c, D, E, g, J, R)
println(A)

