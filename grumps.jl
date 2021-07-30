using StatsFuns, BenchmarkTools, JLD, Optim, TimerOutputs, Random, LinearAlgebra

import Base.Threads.@threads, Base.Threads.@spawn



const to = TimerOutput()

Random.seed!(1)

Flt = AbstractFloat

StructToTuple( s ) = tuple( [ s.:($t) for t ∈ fieldnames(typeof(s))]... )

function ChoiceProbabilities!( π::Matrix{T}, Aθ::Matrix{T}, δ::Vector{T} ) where {T<:Flt}
    for r ∈ axes( π, 1)
        for j ∈ axes(π,2)  π[r,j] = Aθ[r,j] + δ[j] end
        softmax!( @view π[r,:] )
    end
end

function ChoiceProbabilities!( π::Array{T,3}, ZXθ::Array{T,3}, δ::Vector{T} ) where {T<:Flt}
    for i ∈ axes( π, 2)
        for r ∈ axes( π, 1)
            for j ∈ axes(π,3)  π[r,i,j] = ZXθ[r,i,j] + δ[j] end
            softmax!( @view π[r,i,:] )
        end
    end
end


function WeightedSum!( b::Vector{T}, w::Vector{T}, A::Matrix{T} ) where {T<:Flt}
    for j ∈ axes(b,1)
        b[j] = sum( w[r] * A[r,j] for r ∈ 1:length(w) )
    end
    b
end

function WeightedSum!( B::Matrix{T}, w::Vector{T}, A::Matrix{T}, C::Matrix{T} ) where {T<:Flt}
    for j ∈ axes(B,2)
        for i ∈ axes(B,1)
            B[i,j] = sum( w[r] * A[r,i] * C[r,j] for r ∈ 1:length(w) )
        end
    end
    B
end

function WeightedSum!( B::Matrix{T}, w::Vector{T}, A::Matrix{T}, C::Array{T,3} ) where {T<:Flt}
    for j ∈ axes(B,2)
        for i ∈ axes(B,1)
            B[i,j] = sum( w[r] * A[r,i] * C[r,i,j] for r ∈ 1:length(w) )
        end
    end
    B
end


function Symmetrize!(A::Matrix)
    for ind ∈ CartesianIndices( A )
        (k,t) = Tuple( ind )
        k > t && ( A[ind] = A[t,k] )
    end
end




struct MacroData{T<:Flt}
    A   :: Array{T,3}   # data (RM, J, dθ)                          construction
    Ns  :: Vector{T}    # N * s - sum(Y) (J)                        construction                                     
    w   :: Vector{T}    # weights (RM)                              construction
    Aθ  :: Matrix{T}    # A[r,j,:] * θ   (RM, J)                    before δ
    πrj :: Matrix{T}    # choice probabilities for each draw (RM,J) δ 
    πj  :: Vector{T}    # ditto aggregated (J)                      δ
    Σππ :: Matrix{T}    # outer product  (J,J)                      δ
    ρ   :: Vector{T}    # Ns / πj  (J)                              δ 
    Δa  :: Array{T,3}   # intermediate object (RM,J,dθ)             θ
    Δ   :: Array{T,3}   # intermediate object (RM,J,J)              θ
    ΣπA :: Matrix{T}    # intermediate object (J,dθ)                θ
    ρπ  :: Vector{T}    # intermediate object (RM)                  θ
    R   :: Int          # number of replication draws               construction
    J   :: Int          # number of products                        construction
    dθ  :: Int          # number of coefficients                    construction

    function MacroData( A::Array{T2,3}, Ns::Vector{T2}, w::Vector{T2}, ) where {T2<:Flt}
        (R,J,d) = size(A)
        R == length(w)  || throw( DimensionMismatch("💩 number of replications does not match 💩") )
        J == length(Ns) || throw( DimensionMismatch("💩 number of products does not match 💩") )
        Aθ = zeros( T2, R, J);  πj = zeros(T2, J) 
        new{T2}( A, Ns, w,  Aθ, similar(Aθ), πj, zeros(T2, J, J), similar(πj), similar(A), zeros(T2,R,J,J), zeros(T2, J,d), similar(w), R, J, d )
    end

end


GetMacroDataδ( s::MacroData ) = ( s.Ns, s.w, s.Aθ, s.πrj, s.πj, s.Σππ, s.ρ )
GetMacroDataθ( s::MacroData ) = ( s.A, s.Ns, s.w, s.πrj, s.πj, s.ρ, s.Δa, s.Δ,  s.ΣπA, s.ρπ )

function MacroObjectiveδ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, fullδ::Vector{T}, data::MacroData{T} ) where {T<:Flt}
    # initialize
    ( Ns, w, Aθ, πrj, πj, Σππ, ρ ) = GetMacroDataδ( data )  
    computeF =  F ≠ nothing ;  computeG =  G ≠ nothing;  computeH = H ≠ nothing

    # compute choice probabilties 
    ChoiceProbabilities!( πrj, Aθ, fullδ )
    WeightedSum!( πj, w, πrj )

    # compute objective function if desired
    computeF && ( F -= sum( Ns[j] * log( πj[j] ) for j ∈ eachindex(Ns) ) )
    computeG || computeH || return F            # nothing more to do if only F is to be computed

    WeightedSum!( Σππ, w, πrj, πrj )
    ρ .= Ns ./ πj

    # computing gradient if desired
    computeG && for k ∈ axes(G,1) G[k] -= ( Ns[k] - sum( ρ[j] * Σππ[j,k] for j ∈ eachindex(ρ) ) ) end
    computeH || return F                        
    
    for t ∈ axes( H, 2 ) 
        for k ∈ 1:t
            k == t &&  ( H[k,k] +=  sum( ρ[j] * w[r] * πrj[r,j] * πrj[r,k]  for r ∈ axes( πrj, 1), j ∈ axes( πrj, 2 )  ) )
            for j ∈ eachindex(ρ)
                H[k,t] += ρ[j] * Σππ[j,k] * Σππ[j,t] / πj[j] - 2.0 * ρ[j] * sum( w[r] * πrj[r,j] * πrj[r,k] * πrj[r,t] for r ∈ axes(πrj,1) )
            end
        end
    end
    Symmetrize!(H)
    F
end




function Computeπri!( πri::Matrix{T}, πrij::Array{T,3}, y::Vector{Int} ) where {T<:Flt}
    for i ∈ 1:size(πri,2)
        for r ∈ 1:size(πri,1)
           πri[r,i] = πrij[r,i,y[i]] 
        end
    end
    πri
end


# struct MicroDataδ{T<:Flt}
#     ZXθ  :: Array{T,3}
#     πrij :: Array{T,3}
#     πri  :: Matrix{T}
#     Σπ   :: Vector{T}
#     Σππ  :: Matrix{T}
#     y    :: Vector{Int}
#     Y    :: Matrix{Int}
#     w    :: Vector{T}
#     R    :: Int
#     S    :: Int
#     J    :: Int

#     function MicroDataδ( ZXθ :: Array{T2,3}, w :: Vector{T2}, y :: Vector{Int} ) where {T2<:Flt}
#         (R,S,J) = size( ZXθ )
#         R == length(w) || throw( DimensionMismatch("wrong length w"))
#         S == length(y) || throw( DimensionMismatch("wrong length y"))
#         Y = [ y[i] == j for i ∈ 1:S, j ∈ 1:J ]
#         new{T2}( ZXθ, zeros(T2,R,S,J), zeros(T2,R,S), zeros(T2, S), zeros(T2,S,J), y, Y, w, R, S, J )
#     end
# end

struct MicroData{T<:Flt}
    Z    :: Array{T,3}      # data (S,J,dz)                                                 construction
    X    :: Array{T,3}      # data (R,J,dz)                                                 construction
    y    :: Vector{Int}     # data (S)                                                      construction
    Y    :: Matrix{Bool}    # data (S,J)                                                    construction
    w    :: Vector{T}       # data (R)                                                      construction
    ZXθ  :: Array{T,3}      # ZX * θz  (R,S,J)                                              before δ
    πrij :: Array{T,3}      # choice probabilities for each (rep, cons)  (R,S,J)            δ
    πri  :: Matrix{T}       # probability of selected choice for each (rep,cons)  (R,S)     δ
    πi   :: Vector{T}       # weighted average of πri over r                      (S)       δ
    Σππ  :: Matrix{T}       # intermediate object                              (S,J)        δ
    Σπb  :: Matrix{T}       # intermediate object  (S,dθ)                                   θ
    Δb   :: Array{T,4}      # intermediate object  (R,S,J,dθ)                               θ
    R    :: Int             # number of replication draws                                   construction
    S    :: Int             # number of consumers in micro dataset                          construction
    J    :: Int             # number of products                                            construction
    dz   :: Int             # number of z characteristics                                   construction
    dν   :: Int             # number of ν characteristics                                   construction

    function MicroData( Z::Array{T2,3}, X::Array{T2,3}, y::Vector{Int}, w::Vector{T2} ) where {T2<:Flt}
        @info "This is currently not set up to conserve memory; can cut memory use by rewriting use of Δb and also by recomputing πrij and compute Zθ Xθ instead of ZXθ"
        (S,J, dz) = size( Z );  (R,J,dx ) = size( X);  dθ = dx + dz
        R == length(w) || throw( DimensionMismatch("💩 number of replications does not match 💩"))
        S == length(y) || throw( DimensionMismatch("💩 number of consumers does not match 💩"))
        size( Z, 2 ) == J || throw( DimensionMismatch("💩 number of products does not match 💩"))
        all( 1 .≤ y .≤ J ) || throw( ArgumentError("💩 choice not between 1 and J 💩"))
        Y = [ y[i] == j for i ∈ 1:S, j ∈ 1:J ]
        ZXθ = zeros(T2, R, S, J)
        new{T2}( Z, X, y, Y, w, ZXθ, similar(ZXθ), zeros(T2, R, S), similar(y), zeros(T2, S, J), zeros(T2, S, dθ), zeros(T2, R, S , J, dθ), R, S, J, dz, dx  )
    end
    function MicroData( Z::Array{T2,3}, X::Array{T2,3}, Y::Matrix{Bool}, w::Vector{T2} ) where {T2<:Flt}
        (S,J, dz) = size( Z )
        S == size(Y,1) || throw( DimensionMismatch("💩 number of consumers does not match 💩"))
        size( Y, 2 ) == J || throw( DimensionMismatch("💩 number of products does not match in Y 💩"))
        MicroData( Z, X, sum( Y; dims = 2 ), w )
    end
end


GetMicroDataδ( s::MicroData ) = ( s.y, s.Y, s.w, s.ZXθ, s.πrij, s.πri, s.πi, s.Σππ  )
GetMicroDataθ( s::MicroData ) = ( s.Z, s.X, s.y, s.Y, s.w, s.πrij, s.πri, s.πi, s.Σπb, s.Δb )


function MicroObjectiveδ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, δ::Vector{T}, data::MicroData ) where {T<:Flt}
    # initialize
    ( y, Y, w, ZXθ, πrij, πri, πi, Σππ ) = GetMicroDataδ( data )
    computeF = F ≠ nothing; computeG = G ≠ nothing; computeH = H ≠ nothing
    
    # compute choice probabilities
    ChoiceProbabilities!( πrij, ZXθ, δ)
    Computeπri!( πri, πrij, y )
    WeightedSum!( πi, w, πri )

    computeF && ( F -= sum( log( πi[i] ) for i ∈ axes(πi,1) ) )
    computeG || computeH || return F

    # compute gradient
    WeightedSum!( Σππ, w, πri, πrij )
    computeG && for k ∈ axes(G,1) G[k] -= sum( Y[i,k] - Σππ[i,k] / πi[i] for i ∈ axes(Y,1) ) end
    computeH || return F

    # compute Hessian
    for t ∈ axes( H, 2 )
        for k ∈ 1:t
            k == t && ( H[k,t] +=  sum( Σππ[i,t] / πi[i] for i ∈ axes(πi,1) ) )
            for i ∈ axes(Σππ,1)
                H[k,t] += Σππ[i,k] * Σππ[i,t] / πi[i]^2 - 2.0 * sum( w[r] * πri[r,i] * πrij[r,i,k] * πrij[r,i,t] for r ∈ axes(w,1) )  / πi[i]
            end
        end
    end
    Symmetrize!( H )
    F 
end


function ObjectiveFunctionδStandard!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T}, Nothing}, fullδ::Vector{T},  microdata::MicroData, macrodata::MacroData ) where {T<:Flt}

    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
    computeG && ( G .= T(0.0) )
    computeH && ( H .= T(0.0) )

    FM = MacroObjectiveδ!( F, G, H, fullδ, macrodata )
    Fm = MicroObjectiveδ!( F, G, H, fullδ, microdata )
    computeF && ( F = Fm + FM )
    F
end


struct Resultsδ{T<:Flt}
    δ   ::  Vector{T}
    F   ::  Vector{T}
    Gδ  ::  Vector{T}
    Hδδ ::  Matrix{T}

    function Resultsδ( T2::Type, J :: Int ) 
        dδ = J - 1
        new{T2}( zeros(T2,dδ), [ 0.0 ], zeros(T2,dδ), zeros(T2,dδ,dδ) )
    end
end


# computes optimal δ for a given θ where the values of θ are already embedded in microdata and macrodata
# this is standard grumps
function 😠😠😠😠Standardδ!( results::Resultsδ{T}, microdata::MicroData, macrodata::MacroData, startvec::Vector{T} ) where {T<:Flt}
    Ωδ!(  F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, δ::Vector{T} ) where {T<:Flt} =
        ObjectiveFunctionδStandard!( F, G, H, vcat( δ, T(0.0) ), microdata, macrodata )   

    res = optimize(Optim.only_fgh!(Ωδ!), startvec, NewtonTrustRegion(), Optim.Options(show_trace=false, extended_trace=true, x_tol=0.0, g_tol=1.0e-8, iterations=50 ) )
    results.δ .= res.minimizer
    results.F .= Ωδ!( T(0.0), results.Gδ, results.Hδδ, results.δ )
    results
end


GrumpsStandardδ! = 😠😠😠😠Standardδ!

function WeightedDifference!( Δ::Array{T,3}, A::Array{T,3}, π::Matrix{T} ) where {T<:Flt}
    for k ∈ axes( Δ,3 )
        for r ∈ axes( Δ, 1 )
            sm = sum( π[r,t] * A[r,t,k] for t ∈ axes(A,2) )
            for j ∈ axes( Δ, 2 )
               Δ[r,j,k] = A[r,j,k] - sm
            end
        end
    end
end


# weighted sum over second index
function WeightedSum2!( C::Vector{T}, w::Vector{T}, A::Matrix{T} ) where {T<:Flt}
    for i ∈ axes(C, 1)
        C[i] = sum( w[j] * A[i,j] for j ∈ axes(A,2) )
    end
end


function ComputeΔ!( Δ::Array{T,3}, π::Matrix{T} ) where {T<:Flt}
    for k ∈ axes(Δ,3), j ∈ axes(Δ,2), r ∈ axes(Δ,1)
        Δ[r,j,k] = (j==k) - π[r,k]
    end
    Δ
end



function MacroObjectiveθ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, Hθθ::Union{Matrix{T},Nothing}, Hδθ::Union{Matrix{T},Nothing}, θ::Vector{T}, data::MacroData ) where {T<:Flt}
    # This assumes choice probabilities and such have already been computed and reside in data
    # Note that there is typically no point recomputing F since it was already computed in MacroObjectiveδ, but it isn't all that costly
    ( A, Ns, w, πrj, πj, ρ, Δa, Δ, ΣπA, ρπ ) = GetMacroDataθ( data )
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeHθθ = Hθθ ≠ nothing;  computeHδθ = Hδθ ≠ nothing;  computeH = computeHθθ || computeHδθ
 
    computeF && ( F -= sum( Ns[j] * log( πj[j] ) for j ∈ 1:J ) )
    computeG || computeH || return F

    WeightedDifference!( Δa, A, πrj )
    WeightedSum!( ΣπA, w, πrj, Δa  )
    computeG && for k ∈ eachindex(G) G[k] -= sum( ρ[j] * ΣπA[j,k] for j ∈ eachindex(ρ) ) end 
    computeH || return F
 
    # now compute Hessian
    WeightedSum2!( ρπ, ρ, πrj )    
    ComputeΔ!( Δ, πrj )
    if computeHθθ 
        for t ∈ axes( Hθθ,2 )
            for k ∈ 1:t
                for j ∈ axes(πrj,2)
                    Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / πj[j]  + sum( w[r] * ( ρπ[r] - ρ[j] ) * πrj[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ eachindex(w) )
                end
            end
        end
        Symmetrize!( Hθθ )
    end
    computeHδθ || return F
    for t ∈ axes( Hδθ, 2 )
        for k ∈ axes( Hδθ, 1 )
            for j ∈ eachindex(ρ)
                Hδθ[k,t] += sum( w[r] *  πrj[r,j] * Δ[r,j,k] * (  ρ[j]  * ΣπA[j,t] / πj[j] + ( ρπ[r] - ρ[j] )  * Δa[r,j,t] ) for r ∈ eachindex(w)  )
            end
        end
    end
    F
end


function MicroObjectiveθ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, Hθθ::Union{Matrix{T},Nothing}, Hδθ::Union{Matrix{T},Nothing}, θ::Vector{T}, data::MicroData ) where {T<:Flt}
    ( Z, X, y, Y, w, πrij, πri, πi, Σπb, Δb ) = GetMicroDataθ( data )
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeHθθ = Hθθ ≠ nothing;  computeHδθ = Hδθ ≠ nothing;  computeH = computeHθθ || computeHδθ
 
    computeF && ( F -= sum( log( πi[i] ) for i ∈ eachindex( πi ) ) )
    computeG || computeH || return F

    for i ∈ axes( Z, 1 )
        for r ∈ eachindex( w )
            for k ∈ axes( Z, 3 ) 
                avg = sum( πrij[r,i,v] * Z[i,v,k] for v ∈ axes( Z, 2 ) )
                for j ∈ axes(Z,2) #( computeH ? axes( Z,2 ) : y[i] )
                    Δb[r,i,j,k] = Z[i,j,k] - avg 
                end
            end
            for k ∈ axes( X, 3 )
                avg = sum( πrij[r,i,v] * X[r,v,k] for v ∈ axes( X, 2 ) )
                for j ∈ axes(X,2) #( computeH ? axes( X, 2) : y[i] )
                    Δb[r,i,j,k + size(Z,3) ] = X[r,j,k] - avg
                end
            end
        end
    end
    for k ∈ axes( Σπb, 2 )
        for i ∈ axes( Σπb, 1 )
            Σπb[i,k] = sum( w[r] * πri[r,i] * Δb[r,i,y[i],k] for r ∈ eachindex( w ) )
        end
    end

    computeG &&  for k ∈ axes( Σπb,2 )  G[k] -= sum( Σπb[i,k] / πi[i] for i ∈ axes( Σπb, 1 ) ) end
    computeH || return F

    if computeHθθ 
        for t ∈ axes( Hθθ,2 )
            for k ∈ 1:t
                for i ∈ axes( Σπb, 1 )
                    Hθθ[k,t] += Σπb[i,k] * Σπb[i,t] / πi[i]^2
                    for j ∈ axes( Y, 2 )
                        Hθθ[k,t] += sum( w[r] * ( πri[r,i] - Y[i,j] ) * πrij[r,i,j] * Δb[r,i,j,k] * Δb[r,i,j,t] for r ∈ eachindex(w) ) / πi[i]
                    end
                end
            end
        end
        Symmetrize!( Hθθ )
    end
    computeHδθ || return F

    for t ∈ axes(Hδθ, 2)
        for k ∈ axes(Hδθ, 1)
            for i ∈ axes( Σπb, 1)
                Hδθ[k,t] += sum( w[r] * πri[r,i] * πrij[r,i,k] *  ( ( Δb[r,i,y[i],t] + Δb[r,i,k,t] ) / πi[i] -  Σπb[i,t] / πi[i]^2 ) for r ∈ eachindex(w) )
            end
        end
    end
    F
end    


struct GrumpsData{T<:Flt}
    A :: Array{T,3}
    Z :: Array{T,3}
    X :: Array{T,3}
    y :: Vector{Int}
    s :: Vector{T}
    N :: Union{T,Int}
    w :: Vector{T}
    W :: Vector{T}
end


struct MarketData{T<:Flt}
    microdata :: MicroData{T}
    macrodata :: MacroData{T}

    function MarketData( data::GrumpsData{T2} ) where {T2<:Flt} 
        Ns = data.N * data.s
        for i ∈ eachindex(data.y)
            Ns[data.y[i]] -= 1
        end
        new{T2}( MicroData( data.Z, data.X, data.y, data.w ), MacroData( data.A, Ns, data.W ) )
    end
end



struct Resultsθ{T<:Flt}
    F   :: Vector{T}      #  (1)     objective function value
    G   :: Vector{T}      #  (dθ)    gradient
    Hθθ :: Matrix{T}      #  (dθ,dθ) Hessian
    Hδθ :: Matrix{T}      #  (dδ,dθ) part of the larger Hessian
    Resultsθ( T2::Type, dθ::Int, J::Int ) = new{T2}( zeros(T2,1), zeros(T2,dθ), zeros(T2,dθ,dθ), zeros(T2,J-1,dθ) )
end


function ExponentiationCorrection!( G::Union{Vector{T}, Nothing}, Hθθ::Union{Matrix{T}, Nothing}, Hδθ::Union{Matrix{T}, Nothing}, θ::Vector{T}, start::Int ) where {T<:Flt}
    G == nothing || for t ∈ start : length( θ ) G[t] *= θ[t]  end 
    Hδθ == nothing || for t ∈ start:length(θ) Hδθ[:,t] *= θ[t] end
    Hθθ == nothing && return
    for t ∈ start:length(θ)
        Hθθ[t,:] *= θ[t]
        Hθθ[:,t] *= θ[t]
    end
    Hθθ == nothing && return
    G == nothing && throw( ArgumentError("💩 Cannot compute Hθθ without G due to exponentiation issue 💩") )
    for t ∈ start:length(θ)  Hθθ[t,t] += G[t] end
    nothing
end


function ObjectiveFunctionθStandardOneMarket!( resultsθ::Resultsθ{T}, resultsδ::Resultsδ{T}, computeF::Bool, computeG::Bool, computeH::Bool, θ::Vector{T}, microdata::MicroData{T}, macrodata::MacroData{T} ) where {T<:Flt}

    # first calculate δ
    # these constructors might be slow; should check
    dz = size( microdata.Z, 3);  dθ = size( macrodata.A, 3 )
    macrodata.Aθ[:,:] = [ sum( macrodata.A[r,j,t] * θ[t] for t ∈ 1:dθ ) for r ∈ axes( macrodata.A, 1 ), j ∈ axes( macrodata.A, 2 ) ]    
    microdata.ZXθ[:,:,:] =  [ sum( microdata.Z[i,j,t] * θ[t] for t ∈ 1:dz ) + sum( microdata.X[r,j,t] * θ[dz+t] for t ∈ 1:dθ-dz ) for r ∈ axes( microdata.X, 1), i ∈ axes( microdata.Z, 1 ), j ∈ axes( microdata.X, 2 ) ]
    😠😠😠😠Standardδ!( resultsδ, microdata, macrodata, zeros( T, size( macrodata.A, 2  ) - 1  ) )         # compute δ for given θ   
    resultsθ.F .= resultsδ.F

    # return if no derivatives are needed
    computeG || computeH || return 

    # now initialize the various objects
    G = computeG ? resultsθ.G : nothing
    computeG  && ( G .= 0.0 )
    if computeH
        Hθθ = resultsθ.Hθθ
        Hδθ = resultsθ.Hδθ
        Hθθ .= 0.0
        Hδθ .= 0.0
    else 
        Hθθ = nothing; Hδθ = nothing 
    end

    # now do the actual computations, bearing in mind that the gradients and Hessians are added
    MacroObjectiveθ!( nothing, G, Hθθ, Hδθ, θ, macrodata )
    MicroObjectiveθ!( nothing, G, Hθθ, Hδθ, θ, microdata )
    ExponentiationCorrection!( G, Hθθ, Hδθ, θ, size( microdata.Z,3 ) + 1 )
    nothing
end




struct Resultsδθ{T<:Flt}
    resultsδ :: Resultsδ{T}
    resultsθ :: Resultsθ{T}
    function Resultsδθ( data::MarketData{T2} ) where {T2<:Flt}
        (R,J,dθ) = size( data.macrodata.A )
        new{T2}( Resultsδ( T2, J ), Resultsθ( T2, dθ, J ) )
    end
end


function ObjectiveFunctionθStandard!( results::Vector{Resultsδθ{T}}, F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T}, Nothing}, θzexpθν::Vector{T}, data::Vector{MarketData{T}} ) where {T<:Flt}
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
    dz = size( data[1].microdata.Z, 3 );  dθ = size( data[1].macrodata.A, 3 )
    computeH && !computeG && ( computeG = true; G = zeros(T, dθ ) )   # need G for exponentiation if H is to be computed
    θ = [ t ≤  dz ? θzexpθν[t] : exp(θzexpθν[t]) for t ∈ eachindex(θzexpθν) ]

    @sync for m ∈ eachindex(data)
        @spawn ObjectiveFunctionθStandardOneMarket!( results[m].resultsθ, results[m].resultsδ, computeF, computeG, computeH, θ, data[m].microdata, data[m].macrodata )
    end        

    # now compute the objective function, gradient and Hessian, if desired
    computeF && ( F = sum( results[m].resultsθ.F[1] for m ∈ eachindex(results) ) )
    computeG && ( G .= sum( results[m].resultsθ.G for m ∈ eachindex(results) ) )
    computeH && ( H .= sum( results[m].resultsθ.Hθθ - results[m].resultsθ.Hδθ' * inv( results[m].resultsδ.Hδδ ) * results[m].resultsθ.Hδθ for m ∈ eachindex(results) ) )
    F    
end


struct Results{T<:Flt}
    F :: Vector{T}
    θ :: Vector{T}
    δ :: Vector{T}
    Hθθ :: Matrix{T}
    Hδθ :: Matrix{T}
    Hδδ :: Matrix{T}
    Results(T2::Type, dθ::Int, dδ::Int ) = new{T2}( zeros(T2,1), zeros(T2,dθ), zeros(T2,dδ), zeros(T2,dθ,dθ), zeros(T2,dδ,dθ), zeros(T2,dδ,dδ) )
end

function Results( resultsδθ::Vector{ Resultsδθ{T} }, θexp::Vector{T}, F::T, dz::Int  ) where {T<:Flt}
    dθ = length( θexp )
    dδ = [ length( resultsδθ[m].resultsδ.δ ) for m ∈ eachindex(resultsδθ) ]
    dδsum = sum( dδ )
    results = Results( T, dθ, dδsum )
    results.F .= F
    results.θ[:] = [ t ≤ dz ?  θexp[t] : exp( θexp[t] ) for t ∈ 1:dθ ]
    start = 1;  for m ∈ eachindex(resultsδθ)  
        range = start: start+dδ[m]-1
        results.δ[ range ] = resultsδθ[m].resultsδ.δ 
        results.Hθθ .+= resultsδθ[m].resultsθ.Hθθ 
        results.Hδθ[range,:] .= resultsδθ[m].resultsθ.Hδθ 
        results.Hδδ[range,range] = resultsδθ[m].resultsδ.Hδδ 
        start += dδ[m]
    end
    results
end


function 😠😠😠😠Standard( θstart::Vector{T}, data::Vector{GrumpsData{T}}  )   where {T<:Flt}
    marketdata = [ MarketData( data[m] ) for m ∈ eachindex(data) ]
    resultsδθ = [ Resultsδθ( marketdata[m] ) for m ∈ eachindex(data)  ]
    Ω!( F::Union{T, Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, θzexpθν::Vector{T} ) =  ObjectiveFunctionθStandard!( resultsδθ, F, G, H, θzexpθν, marketdata ) 
    dz = size( marketdata[1].microdata.Z, 3 );  dθ = size( marketdata[1].macrodata.A, 3);  
    dδ = zeros( Int, length(data) )
    for m ∈ eachindex(marketdata)
        dδ[m] = size( marketdata[m].macrodata.A, 2) - 1
    end
    dδsum = sum( dδ )
    # dδ = [ size( data[m].macrodata.A, 2 ) -1 for m ∈ eachindex(data) ];  dδsum = sum( dδ )
    θzexpθνstart = [ t ≤ dz ? θstart[t] : log( θstart[t] ) for t ∈ eachindex(θstart) ]
    res = optimize( Optim.only_fgh!(Ω!), θzexpθνstart, NewtonTrustRegion(), Optim.Options(show_trace=true, extended_trace = true, x_tol=0.0, g_tol=1.0e-4, iterations=50 ) )
    Ω!( 0.0, zeros( T, dθ ), zeros( T, dθ, dθ ), res.minimizer   )
    Results( resultsδθ, res.minimizer, res.minimum, dz )
end

GrumpsStandard = 😠😠😠😠Standard


function LoadIt(fn::String)
    dic = load(fn)
    y = dic["y"]
    Y = dic["Y"]
    Z = dic["Z"]
    X = dic["X"]
    s = dic["s"]
    A = dic["A"]
    w = dic["w"]
    W = dic["W"]
    N = dic["N"]
    ( y, Y, Z, X, s, A, w, W, N )
end

dot(x::Vector{T},y::Vector{T2}) where {T<:Real, T2<:Real }= sum( x[i] * y[i] for i ∈ 1: length(x) )

function loadshit( m::Int )
    ( y, Y, Z, X, s, A, w, W, N ) = LoadIt("scratch$(m).jld") 
    ( S, J, dz ) = size( Z )
    R = length(w);  RM = length(W)
    dx = size(X,3);  dxz = dx + dz
    GrumpsData( A, Z, X, y, s, N, w, W )
end



function RunIt(M::Int, dθ::Int)
    run(`clear`)
    data = [ loadshit( m ) for m ∈ 1:M ] 
    @time results = 😠😠😠😠Standard( [0.5; 0.5; 0.5; 0.5; 0.5] , data )
    display( results );  println()
    sleep(3)
    @time results = 😠😠😠😠Standard( [0.5; 0.5; 0.5; 0.5; 0.5] , data )
    display( results );  println()
end


RunIt(5, 5)

