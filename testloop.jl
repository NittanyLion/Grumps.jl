using BenchmarkTools


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


function poop1( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    for k ∈ axes( Hθθ, 1 )
        for t ∈ axes( Hθθ, 2 )
            for j ∈ axes( ΣπA, 1 )
                Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j]
                for r ∈ 1:length(w)
                    Hθθ[k,t] += w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t]
                end
            end
        end
    end
    Hθθ
end

function poop2( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    for k ∈ axes( Hθθ, 1 )
        for t ∈ axes( Hθθ, 2 )
            for j ∈ axes( ΣπA, 1 )
                Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j]
                for r ∈ 1:length(w)
                    Hθθ[k,t] += w[r] * ρπ[r] * π[r,j] * Δa[r,j,k] * Δa[r,j,t]
                    Hθθ[k,t] -= w[r] * ρ[j] * π[r,j] * Δa[r,j,k] * Δa[r,j,t]
                end
            end
        end
    end
    Hθθ
end

function poop3( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    for k ∈ axes( Hθθ, 1 )
        for t ∈ axes( Hθθ, 2 )
            for j ∈ axes( ΣπA, 1 )
                Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j] + sum( w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ 1:length(w) )
            end
        end
    end
    Hθθ
end

function poop4( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    for t ∈ axes( Hθθ, 2 )
        for k ∈ axes( Hθθ, 1 )
            for j ∈ axes( ΣπA, 1 )
                Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j] + sum( w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ 1:length(w) )
            end
        end
    end
    Hθθ
end


function poop5( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    for t ∈ axes( Hθθ, 1 ),  k ∈ axes( Hθθ, 2 )
        for j ∈ axes( ΣπA, 1 )
            Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j] + sum( w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ 1:length(w) )
        end
    end
    Hθθ
end


function poop6( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
    Hθθ .= 0.0
    for t ∈ axes( Hθθ, 2 )
        for k ∈ 1:t
            for j ∈ axes( ΣπA, 1 )
                Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j] + sum( w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ 1:length(w) )
            end
        end
    end
    for t ∈ axes( Hθθ, 2 )
        for k ∈ t+1: size(Hθθ,1)
            Hθθ[k,t] = Hθθ[t,k]
        end
    end
    Hθθ
end


println( poop1( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
println( poop2( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
println( poop3( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
println( poop4( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
println( poop5( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
println( poop6( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
@btime poop1( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )
@btime poop2( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )
@btime poop3( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )
@btime poop4( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )
@btime poop5( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )
@btime poop6( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )

