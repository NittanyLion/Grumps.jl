using BenchmarkTools, LoopVectorization

import Base.Threads.@threads 


const N = 1000

A = randn(N,N)

function Symmetrize!(A::Matrix)
    for ind ∈ CartesianIndices( A )
        (k,t) = Tuple( ind )
        k > t && ( A[ind] = A[t,k] )
    end
end


@btime Symmetrize!( $A )
