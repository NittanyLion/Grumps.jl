


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
    count = 0
    for 𝓁 ∈ readlines( "$(@__DIR__)/notes.txt" )  
        count += 1
        printstyled( "$count: $𝓁\n"; bold = false ) 
    end
    println()
end

end

