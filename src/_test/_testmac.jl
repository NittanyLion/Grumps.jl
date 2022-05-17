push!(LOAD_PATH, "..")
using Grumps, Serialization

Grumps.@Imports()
const T = Float64

function getstuff()
    𝒳 = deserialize( "_macX.ser" )
    𝒟 = deserialize( "_macD.ser" )
    sh = deserialize( "_s.ser" )
    N = deserialize( "_N.ser" )
    w = deserialize( "_macw.ser" )
    Aθ = deserialize( "_Atheta.ser" )
    θ = deserialize( "_theta.ser" )
    δ = deserialize( "_delta.ser" )
    d = Grumps.GrumpsMacroDataAnt{T}( "whocares", 𝒳, 𝒟, sh, T(N), w )
    s = Grumps.GrumpsMacroSpace( 
        length( w ),
        size( 𝒳, 1 ),
        size( 𝒳, 2 ),
        false )
    copyto!( s.Aθ, Aθ )
    o = Grumps.OptimizationOptions()
    return d, s, o, θ, δ
end

function dostuff()
    d, s, o, θ, δ = getstuff()
    dθ = length( θ )
    dδ = length( δ )
    F = zero( T )
    G = zeros( T, dθ )
    Hθθ = zeros( T, dθ, dθ )
    Hδθ = zeros( T, dδ, dθ)
    Fval = Grumps.MacroObjectiveθ!( F, G, Hθθ, Hδθ, θ, δ, d, s, o, true )
    println( "Fval = ", Fval)
    println( "G = $G" )
    println( "Hθθ = $Hθθ" )
    println( "Hδθ = $Hδθ" )
end

dostuff()

