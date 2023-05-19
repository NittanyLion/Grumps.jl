using GrumpsEstimation
using Test
using LinearAlgebra

GrumpsEstimation.advisory( "number of BLAS threads used = $(BLAS.get_num_threads())" )

@testset "GrumpsEstimation.jl" begin
    include( "testexample.jl" )
end
