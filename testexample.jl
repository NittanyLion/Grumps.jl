


using BenchmarkTools
import Base.Threads.@threads 

const N = 3
const K = 10_000

B = randn( N, K )
C = randn( K, N )
A = zeros( N, N )

function f1( A, B, C )
    @threads for j ∈ axes( A, 2 )  # A is square; may or may not be large
        for i ∈ 1:j
            A[i,j] = sum( log( (B[i,k] * C[k,j])^2 + 1.0)  for k ∈ axes(B,2) )  # some costly operation
        end
    end
    A
end

# function f2( A, B, C )
#     @threads for j ∈ axes( A, 2 ), i ∈ 1:j   # produces an error
#             A[i,j] = sum( log( (B[i,k] * C[k,j])^2 + 1.0)  for k ∈ axes(B,2)  )  # some costly operation
#         end
#     end
# end

function grabindices( A::Matrix, i::Int ) 
    k = mod( i - 1, size( A, 1 ) ) + 1
    (k, div( i - k, size( A, 1 ) ) + 1 )
end

function f3( A, B, C )
    @threads for ind ∈ length( A )
        (i, j) = grabindices( A, ind )
        i > j && continue
        A[ind] = sum( log( (B[i,k] * C[k,j])^2 + 1.0)  for k ∈ axes(B,2) )  # some costly operation
    end
    A
end

function f4( A, B, C )
    @threads for ind ∈ CartesianIndices( A )
        (i, j) = (ind[1], ind[2])
        i > j && continue
        A[ind] = sum( log( (B[i,k] * C[k,j])^2 + 1.0)  for k ∈ axes(B,2) )  # some costly operation
    end
    A
end

display( f1(A,B,C) ); println()
display( f3(A,B,C) ); println()
display( f4(A,B,C) ); println()
@btime f1( $A, $B, $C)
@btime f3( $A, $B, $C)
@btime f4( $A, $B, $C)

