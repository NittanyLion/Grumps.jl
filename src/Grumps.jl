


module Grumps

# run(`clear`)


include( "debug.jl" )


include( "exports.jl" )
include( "includes.jl" )
@info "loaded all code"

const Grumps_version = v"0.1.1"
export Grumps_version
const GrumpsColor = [ :red, :green, :yellow, :blue, :magenta, :cyan ]

const defaultsplashprobs = [ 1.0, 0.0, 0.0, 1.0 ]


function __init__()

    sp = ( isdefined( Main, :splashprobs ) && typeof( Main.splashprobs ) == Vector{Float64} ) ?
                            Main.splashprobs : defaultsplashprobs
    println()
    p = rand(4)

    if p[4] ≤ sp[4]
        color = p[1] ≤ sp[1]
        blink = p[2] ≤ sp[2]
        reverse = p[3] ≤ sp[3]

        count = 0
        for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  
            count = mod( count, 6 ) + 1
            clr = color ? GrumpsColor[count] : :default
            printstyled( "          $𝓁\n"; bold = true, color = clr, blink = blink, reverse = reverse  ) 
        end
    end
    println()
    printstyled( " Please note:\n"; bold = true, color=:green )
    count = 0
    for 𝓁 ∈ readlines( "$(@__DIR__)/notes.txt" )  
        count += 1
        printstyled( "$count: $𝓁\n"; bold = false ) 
    end
    println()
    printstyled( "This is Grumps version $Grumps_version: check for updates regularly\n\n\n"; color= 206, bold = true ); 
end

end

