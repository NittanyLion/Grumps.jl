using BenchmarkTools, LoopVectorization

import Base.Threads.@threads 


const R = 2
const C = 1000

A = zeros(R,C)
X = randn(R,C)
Y = randn(R,C)

function f1(A,X,Y)
    @threads for ind ∈ CartesianIndices( A )
        (i,j) = Tuple(ind)
        i > j && continue
        A[i,j] = log( (X[i,j] * Y[i,j])^2 + 1.0 )
    end
    A
end

# function f2(A,X,Y)
#     A .= X .* Y
# end

function f3(A,X,Y)
    @threads for j ∈ axes(A,2)
        for i ∈ 1:j
            A[i,j] = log( (X[i,j] * Y[i,j])^2 + 1.0 )
        end
    end
    A
end


display(f1(A,X,Y)[1:2,1:2]); println()
# display(f2(A,X,Y)[1:2,1:2]); println()
display(f3(A,X,Y)[1:2,1:2]); println()
@btime f1($A,$X,$Y)
# @btime f2($A,$X,$Y)
@btime f3($A,$X,$Y)

