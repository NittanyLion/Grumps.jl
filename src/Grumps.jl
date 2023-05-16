


module Grumps

# run(`clear`)


include( "debug.jl" )


include( "exports.jl" )
include( "includes.jl" )
@info "loaded all code"


const GrumpsColor = [ :red, :green, :yellow, :blue, :magenta, :cyan ]

function __init__()
    println()
    if isdefined( Main, :SplashColor ) || rand() > 0.5
        count = 0
        for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  
            count = mod( count, 6 ) + 1
            printstyled( "$𝓁\n"; bold = true, color = GrumpsColor[count]  ) 
        end
    else
        for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  printstyled( "$𝓁\n"; bold = true, color=:blink  ) end
    end
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

