


module Grumps

# run(`clear`)


include( "debug.jl" )

@todo 2 "need to increase exports"
export grumps, GrumpsSources, GrumpsEstimate, GrumpsSolution, OptimOptionsθ, OptimOptionsδ, GrumpsTypes, Estimators

include( "includes.jl" )
@info "loaded all code"

function __init__()
    println()
    for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  printstyled( "$𝓁\n"; bold = true, color=:blink  ) end
    println()
    printstyled( " Please note:\n"; bold = true, color=:green )
    println(" 1: read the manual")
    println(" 2: this is a preliminary version")
    println(" 3: still need to put in designed quadrature")
    println(" 4: does not do CUDA")
    println(" 5: uses multithreading, but no distributed computing")
    println(" 6: does not do multinomial logit")
    println(" 7: please direct all questions/suggestions/comments to Joris Pinkse at joris@psu.edu\n\n")
end

end

