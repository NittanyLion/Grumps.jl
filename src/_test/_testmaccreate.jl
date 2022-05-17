using Serialization, StatsFuns, Random



Random.seed!( 2 )


function createandsave()
    R = 100_000
    N = 100_000
    dθ = 5
    dδ = 10
    J = dδ + 1

    𝒳 = randn( J, dθ )
    𝒳[end,:] .= 0.0
    𝒟 = randn( R, dθ )
    s = rand( J )
    s ./= sum( s )
    serialize( "_s.ser", s )
    serialize( "_macX.ser", 𝒳 )
    serialize( "_macD.ser", 𝒟 )
    serialize( "_N.ser", N )
    θ = randn( dθ )
    θ[4:dθ] = abs.( θ[4:dθ] )
    δ = randn( dδ )
    serialize( "_theta.ser", θ )
    serialize( "_delta.ser", δ )
    w = fill( 1.0/R, R )
    serialize( "_macw.ser", w )
    A = zeros( R, J, dθ )
    for r ∈ 1:R, j ∈ 1:J, t ∈ 1:dθ
        A[r,j,t] = 𝒟[r,t] * 𝒳[j,t]
    end
    Aθ = [ sum( A[r,j,t] * θ[t] for t ∈ 1:dθ ) for r ∈ 1:R, j ∈ 1:J ]
    Threads.@threads for r ∈ 1:R
        softmax!( @view Aθ[r,:] )
    end
    serialize( "_Atheta.ser", Aθ )
end

createandsave()