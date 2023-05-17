


module Grumps

# run(`clear`)


include( "debug.jl" )


include( "exports.jl" )
include( "includes.jl" )
@info "loaded all code"

const Grumps_version = v"0.1.0"
export Grumps_version
const GrumpsColor = [ :red, :green, :yellow, :blue, :magenta, :cyan ]

# function __init__()
#     println()
#     if isdefined( Main, :SplashColor ) || rand() > 0.5
#         count = 0
#         for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  
#             count = mod( count, 6 ) + 1
#             printstyled( "$𝓁\n"; bold = true, color = GrumpsColor[count], blink = true, reverse = true  ) 
#         end
#     else
#         for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  printstyled( "$𝓁\n"; bold = true, color=:blink  ) end
#     end
#     println()
#     printstyled( " Please note:\n"; bold = true, color=:green )
#     count = 0
#     for 𝓁 ∈ readlines( "$(@__DIR__)/notes.txt" )  
#         count += 1
#         printstyled( "$count: $𝓁\n"; bold = false ) 
#     end
#     println()
#     printstyled( "This is Grumps version $Grumps_version\n\n"; color= 206, bold = true, blink = true )
# end


function __init__()
    println()
    color = ( rand() > 0.2 )
    blink = ( rand() > 0.5 )
    reverse = ( rand() > 0.8 )

    count = 0
    for 𝓁 ∈ readlines( "$(@__DIR__)/splash.txt" )  
        count = mod( count, 6 ) + 1
        clr = color ? GrumpsColor[count] : :default
        printstyled( "$𝓁\n"; bold = true, color = clr, blink = blink, reverse = reverse  ) 
    end
    println()
    printstyled( " Please note:\n"; bold = true, color=:green )
    count = 0
    for 𝓁 ∈ readlines( "$(@__DIR__)/notes.txt" )  
        count += 1
        printstyled( "$count: $𝓁\n"; bold = false ) 
    end
    println()
    printstyled( "This is Grumps version $Grumps_version: "; color= 206, bold = true ); 
    println( "check for updates regularly\n\n\n" )
end

end

