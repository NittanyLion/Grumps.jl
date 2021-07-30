using BenchmarkTools, LoopVectorization

import Base.Threads.@threads 

const J = 10
const R = 10_000
const d = 5
Hθθ = zeros( d, d )
ρ = randn(J)
ρπ = randn(R)
ΣπA = randn( J, d )
Σπ = randn(J)
w = randn(R)
Δa = randn(R,J,d)
π = randn(R,J)


function poop3( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    @threads for k ∈ axes( Hθθ, 1 )
        for t ∈ axes( Hθθ, 2 )
            for j ∈ axes( ΣπA, 1 )
                Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j] + sum( w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ 1:length(w) )
            end
        end
    end
    Hθθ
end


function grabindices( A::Matrix, i::Int ) 
     k = mod( i - 1, size( A, 1 ) ) + 1
     (k, div( i - k, size( A, 1 ) ) + 1 )
end

    



function poop3a( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    @threads for i ∈ 1: length(Hθθ) 
            ( k, t ) = grabindices( Hθθ, i)
            for j ∈ axes( ΣπA, 1 )
                Hθθ[i] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j] + sum( w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ 1:length(w) )
            end
    end
    Hθθ
end

println( poop3( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
println( poop3a( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
@btime poop3( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )
@btime poop3a( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )