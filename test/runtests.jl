using Grumps
using Test
using LinearAlgebra

Grumps.advisory( "number of BLAS threads used = $(BLAS.get_num_threads())" )

@testset "Grumps.jl" begin
    include( "testexample.jl" )
end
