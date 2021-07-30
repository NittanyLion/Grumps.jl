using LinearAlgebra

import Base.Threads.@threads, Base.Threads.@spawn 

BLAS.set_num_threads(1)

const n = 4
const N = 1_000_000
const tm = [ rand(1:2999:3_000) for i ∈ 1:n ]
println( tm )
const A = [ randn( tm[i], tm[i] ) for i ∈ 1:n ]
v = zeros( n )

function f1( v::Vector{Float64}, A::Vector{Matrix{Float64}}  ) 
    v .= 0.0
    @threads for i ∈ 1:n
        v[i] = sum( inv( A[i] ) )
    end
    v
end

function f2( v::Vector{Float64}, A::Vector{Matrix{Float64}} )
    v .= 0.0
    @sync for i ∈ 1:n
        @spawn begin  v[i] = sum( inv( A[i] ) ) end
    end
    v
end

@time println( f1(v,A) )
@time println( f2(v,A) )

@info "now for real"
@time f1(v,A)
@time f2(v,A)