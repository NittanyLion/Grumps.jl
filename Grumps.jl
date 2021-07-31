# This is the main module that pulls in the code
# from the other files.

module Grumps

export 😠😠😠😠Standard, 😠😠😠😠SC
export GrumpsData



include( "packages.jl" )    # package loading
include( "structures.jl" )  # data structures
include( "basics.jl" )      # auxiliary functions
include( "delta.jl" )       # computation of δ
include( "theta.jl" )       # computation of θ


end

