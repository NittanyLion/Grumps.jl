


module Grumps

# run(`clear`)


include( "debug.jl" )


include( "exports.jl" )
include( "includes.jl" )
@info "loaded all code"

function __init__()
    println()
    for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  printstyled( "$𝓁\n"; bold = true, color=:blink  ) end
    println()
    printstyled( " Please note:\n"; bold = true, color=:green )
    println(" 1: read the manual on github")
    println(" 2: this is a preliminary version")
    println(" 3: still need to put in designed quadrature")
    println(" 4: does not do CUDA")
    println(" 5: uses multithreading, but no distributed computing")
    println(" 6: several methods will be added soon")
    println(" 7: because of the way the random numbers for MC integration are drawn / multithreading, successive optimizations with the same data may not produce the exact same results")
    println(" 8: if you see unexpected behavior, please send me code and data so that I can replicate")
    println(" 9: please direct all questions/suggestions/comments to Joris Pinkse at joris@psu.edu\n\n")

end

end

