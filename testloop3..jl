using BenchmarkTools, LoopVectorization

import Base.Threads.@threads 

const J = 10
const R = 121
const d = 5
const S = 1_000

H = zeros( J-1, J-1 )
Σπ = randn(S)
Σππ = randn( S, J )
w = randn(R)
πri = randn(R,S)
πrij = randn(R,S,J)


function poop( H, Σππ, Σπ, w, πri, πrij )
    H .= 0.0
    for t ∈ axes(H,2)
        for i ∈ axes(Σππ,1)
            H[t,t] +=  Σππ[i,t] / Σπ[i] 
            for k ∈ 1:t
                H[k,t] += Σππ[i,k] * Σππ[i,t] / Σπ[i]^2 - 2.0 * sum( w[r] * πri[r,i] * πrij[r,i,k] * πrij[r,i,t] for r ∈ axes(w,1) )  / Σπ[i]
            end
        end
    end
    H
end

function grabindices( A::Matrix, i::Int ) 
    k = mod( i - 1, size( A, 1 ) ) + 1
    (k, div( i - k, size( A, 1 ) ) + 1 )
end


function poop2( H, Σππ, Σπ, w, πri, πrij )
    H .= 0.0
    for ind ∈ 1:div( size(H,1) * (size(H,1) +1 ), 2)
        (k,t) = grabindices( H, ind )
        for i ∈ axes(Σππ,1)
            H[ind] += ( (k == t) ? ( Σππ[i,t] / Σπ[i] ) : 0.0  ) +  Σππ[i,k] * Σππ[i,t] / Σπ[i]^2 - 2.0 * sum( w[r] * πri[r,i] * πrij[r,i,k] * πrij[r,i,t] for r ∈ axes(w,1) )  / Σπ[i]
        end
    end
    H
end


    



# function poop3a( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa )
#     Hθθ .= 0.0
#     @threads for i ∈ 1: length(Hθθ) 
#             ( k, t ) = grabindices( Hθθ, i)
#             for j ∈ axes( ΣπA, 1 )
#                 Hθθ[i] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / Σπ[j] + sum( w[r] * ( ρπ[r] - ρ[j] ) * π[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ 1:length(w) )
#             end
#     end
#     Hθθ
# end

display( poop( H, Σππ, Σπ, w, πri, πrij ) )
display( poop2( H, Σππ, Σπ, w, πri, πrij ) )
# println( poop3a( Hθθ, ρ, ρπ, ΣπA, Σπ, w, π, Δa ) )
@btime poop( $H, $Σππ, $Σπ, $w, $πri, $πrij )
@btime poop2( $H, $Σππ, $Σπ, $w, $πri, $πrij )
# @btime poop3a( $Hθθ, $ρ, $ρπ, $ΣπA, $Σπ, $w, $π, $Δa )