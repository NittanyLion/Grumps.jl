push!(LOAD_PATH, "../../texascars/grumps-modular")
using Grumps, Serialization


const T = Float64

function getstuff()
    𝒳 = deserialize( "_macX.ser" )
    𝒟 = deserialize( "_macD.ser" )
    s = deserialize( "_s.ser" )
    N = deserialize( "_N.ser" )
    w = deserialize( "_macw.ser" )
    Aθ = deserialize( "_Atheta.ser" )
    θ = deserialize( "_theta.ser" )
    δ = deserialize( "_delta.ser" )
    A = Grumps.AData( 𝒟, 𝒳 )
    Ns = N * s 
    d = Grumps.MacroData( A, Ns, s, w, zeros(T, 0,0) )
    copyto!( d.Aθ, Aθ )
    o = Grumps.Options( T )
    return d, o, θ, δ
end

function dostuff()
    d, o, θ, δ = getstuff()
    dθ = length( θ )
    dδ = length( δ )
    F = zero( T )
    G = zeros( T, dθ )
    Hθθ = zeros( T, dθ, dθ )
    Hδθ = zeros( T, dδ, dθ)
    Grumps.ChoiceProbabilities!( d.πrj, d.Aθ, vcat(δ, 0.0), o )
    Grumps.WeightedSum!( d.πj, d.w, d.πrj ) 
    d.ρ .= d.Ns ./ d.πj 
    for r ∈ eachindex( d.w )
        @inbounds d.ρπ[r] = sum( d.ρ[j] * d.πrj[r,j] for j ∈ eachindex(d.ρ) )                                                 # intermediate object
    end
    Fval = Grumps.MacroObjectiveθ!( F, G, Hθθ, Hδθ, θ, d, o; setzero = true )
    println( "Fval = ", Fval)
    println( "G = $G" )
    println( "Hθθ = $Hθθ" )
    println( "Hδθ = $Hδθ" )
end

dostuff()

