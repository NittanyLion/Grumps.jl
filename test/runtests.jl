using Grumps
using Test
using LinearAlgebra
using Aqua


Aqua.test_all( Grumps; ambiguities=(recursive=false)) 

Grumps.advisory( "number of BLAS threads used = $(BLAS.get_num_threads())" )



@testset "Grumps.jl" begin
    include( "testexample.jl" )
end
