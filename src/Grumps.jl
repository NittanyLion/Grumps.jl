


module Grumps


include( "debug.jl" )
include( "exports.jl" )
include( "includes.jl" )

@info "included all code"

const Grumps_version = v"0.2.4"
export Grumps_version
const GrumpsColor = [ :red, :green, :yellow, :blue, :magenta, :cyan ]

const defaultsplashprobs = [ 1.0, 0.0, 0.0, 1.0 ]


function zebraprint( s :: String )
    for i ∈ eachindex( s )
        printstyled( s[i]; color = GrumpsColor[ i % 6 + 1 ], bold = true )
    end
end



function __init__()

    OhMyREPL.input_prompt!( "GruMPS> ", :green) 
    OhMyREPL.output_prompt!( "GruMPS> ", :blue) 

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

    lastversiondate = try 
        readlines( "$(@__DIR__)/versiondate" )[1] |> Date
    catch
        Date( "2023-09-03" )
    end
    printstyled( "This is Grumps version $Grumps_version ($lastversiondate)\n\n\n"; color= 206, bold = true ); 
    versionage = Day( today() - lastversiondate ) |> Dates.value
    if  versionage ≥ 60
        zebraprint( "Your version of Grumps is $versionage days old: please check for updates regularly!\n\n\n")
    end

end




end

