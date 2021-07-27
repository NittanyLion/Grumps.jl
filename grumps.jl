using StatsFuns, BenchmarkTools, JLD, Optim, TimerOutputs, Random

import Base.Threads.@threads


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

function ChoiceProbabilities!( π::Array{T,3}, Aθ::Array{T,3}, δ::Vector{T} ) where {T<:Flt}
    for i ∈ axes( π, 2)
        for r ∈ axes( π, 1)
            for j ∈ axes(π,3)  π[r,i,j] = Aθ[r,i,j] + δ[j] end
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
    Ns  :: Vector{T}    # N*s (J)                                   construction                                     
    w   :: Vector{T}    # weights (RM)                              construction
    Aθ  :: Matrix{T}    # A[r,j,:] * θ   (RM, J)                    before δ
    πrj :: Matrix{T}    # choice probabilities for each draw (RM,J) δ 
    πj  :: Vector{T}    # ditto aggregated (J)                      δ
    Σππ :: Matrix{T}    # outer product  (J,J)                      δ
    ρ   :: Vector{T}    # Ns / πj  (J)                              δ 
    Δa  :: Array{T,3}   # intermediate object (RM,J,dθ)             θ
    ΣπA :: Matrix{T}    # intermediate object (J,dθ)                θ
    ρπ  :: Vector{T}    # intermediate object (RM)                  θ

    function MacroData( A::Array{T2,3}, Ns::Vector{T2}, w::Vector{T2}, ) where {T2<:Flt}
        (R,J,d) = size(A)
        R == length(w)  || throw( DimensionMismatch("😡 number of replications does not match 😡") )
        J == length(Ns) || throw( DimensionMismatch("😡 number of products does not match 😡") )
        Aθ = zeros( T2, R, J);  πj = zeros(T2, J) 
        new{T2}( A, Ns, w,  Aθ, similar(Aθ), πj, zeros(T2, J, J), similar(πj), similar(A), zeros(T2, J,d), similar(w) )
    end

end


GetMacroDataδ( s::MacroData ) = ( s.Ns, s.w, s.Aθ, s.πrj, s.πj, s.Σππ, s.ρ )



function MacroObjectiveδ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, fullδ::Vector{T}, data::MacroData ) where {T<:Flt}
    @info "this function adds to the various objects"

    # initialize
    ( Ns, w, Aθ, πrj, πj, Σππ, ρ ) = GetMacroDataδ( data )  
    computeF =  F ≠ nothing ;  computeG =  G ≠ nothing;  computeH = H ≠ nothing

    # compute choice probabilties 
    ChoiceProbabilities!( πrj, Aθ, fullδ )
    WeightedSum!( πj, w, πrj )

    # compute objective function if desired
    computeF && ( F -= sum( Ns[j] * log( πj[j] ) for j ∈ axes(Ns,1) ) )
    computeG || computeH || return F            # nothing more to do if only F is to be computed

    WeightedSum!( Σππ, w, πrj, πrj )
    ρ .= Ns ./ πj

    # computing gradient if desired
    computeG && for k ∈ axes(G,1) G[k] -= ( Ns[k] - sum( ρ[j] * Σππ[j,k] for j ∈ axes(ρ,1) ) ) end
    computeH || return F                        
    
    for t ∈ axes( H, 2 ) 
        for k ∈ 1:t
            k == t &&  ( H[k,k] +=  sum( ρ[j] * w[r] * πrj[r,j] * πrj[r,k]  for r ∈ axes( πrj, 1), j ∈ axes( πrj, 2 )  ) )
            for j ∈ axes(ρ,1)
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

    function MicroData( Z::Array{T2,3}, X::Array{T2,3}, y::Vector{Int}, w::Vector{T2} ) where {T2<:Flt}
        @info "This is currently not set up to conserve memory; can cut memory use by recomputing πrij and compute Zθ Xθ instead of ZXθ"
        (S,J, dz) = size( Z );  (R,J,dx ) = size( X);  dθ = dx + dz
        R == length(w) || throw( DimensionMismatch("😡 number of replications does not match 😡"))
        S == length(y) || throw( DimensionMismatch("😡 number of consumers does not match 😡"))
        size( Z, 2 ) == J || throw( DimensionMismatch("😡 number of products does not match 😡"))
        all( 1 .≤ y .≤ J ) || throw( ArgumentError("😡 choice not between 1 and J 😡"))
        Y = [ y[i] == j for i ∈ 1:S, j ∈ 1:J ]
        ZXθ = zeros(T2, R, S, J)
        new{T2}( Z, X, y, Y, w, ZXθ, similar(ZXθ), zeros(T2, R, S), similar(y), zeros(T2, S, J)  )
    end
    function MicroData( Z::Array{T2,3}, X::Array{T2,3}, Y::Matrix{Bool}, w::Vector{T2} ) where {T2<:Flt}
        (S,J, dz) = size( Z )
        S == size(Y,1) || throw( DimensionMismatch("😡 number of consumers does not match 😡"))
        size( Y, 2 ) == J || throw( DimensionMismatch("😡 number of products does not match in Y 😡"))
        MicroData( Z, X, sum( Y; dims = 2 ), w )
    end
end


GetMicroDataδ( s:: MicroData ) = ( s.y, s.Y, s.w, s.ZXθ, s.πrij, s.πri, s.πi, s.Σππ )



function MicroObjectiveδ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, δ::Vector{T}, data::MicroData ) where {T<:Flt}
    @info "this function adds to the objective function, gradient, etc"
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


function ObjectiveFunctionδStandard( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T}, Nothing}, fullδ::Vector{T},  microdata::MicroData, macrodata::MacroData ) where {T<:Flt}

    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
    computeG && ( G .= T(0.0) )
    computeH && ( H .= T(0.0) )

    FM = MacroObjectiveδ!( F, G, H, fullδ, macrodata )
    Fm = MicroObjectiveδ!( F, G, H, fullδ, microdata )
    computeF && ( F = Fm + FM )
    F
end


# computes optimal δ for a given θ where the values of θ are already embedded in microdata and macrodata
# this is standard grumps
function 😠😠😠😠Standardδ( microdata::MicroData, macrodata::MacroData, startvec::Vector{T} ) where {T<:Flt}
    Ωδ!(  F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, δ::Vector{T} ) where {T<:Flt} =
        ObjectiveFunctionδStandard( F, G, H, vcat( δ, T(0.0) ), microdata, macrodata )   

    result = optimize(Optim.only_fgh!(Ωδ!), startvec, NewtonTrustRegion(), Optim.Options(show_trace=true, x_tol=0.0, g_tol=1.0e-8, iterations=50 ) )
    optδ = result.minimizer
    J = length( startvec ) + 1
    G = zeros(T, J-1);  H = zeros(T, J-1, J-1)
    F = Ωδ!( T(0.0), G, H, optδ )
    ( optδ, F, G, H )
end




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
    for k ∈ axes(Δ,3), j ∈ axes(Δ,2), i ∈ axes(Δ,1)
        Δ[i,j,k] = (j==k) - π[i,k]
    end
    Δ
end

# struct MacroDataθ{T<:Flt}
#     A  ::  Array{T,3}
#     πrj :: Matrix{T}
#     πj  :: Vector{T}
#     ρ   :: Vector{T}
#     Ns  :: Vector{T}
#     w   :: Vector{T}
#     Δa  :: Array{T,3}
#     ΣπA :: Matrix{T}
#     ρπ  :: Vector{T}

#     function MacroDataθ( A::Array{T2,3}, w::Vector{T2}, Ns::Vector{T2} ) where {T2<:Flt}
#         (R,J,d) = size(A)
#         new{T2}( A, zeros(T2.R, J, d), similar(Ns), similar(Ns) , Ns, w, similar(A), zeros(T2, J, d), similar(w) )
#     end

#     function MacroDataθ!( θdata::MacroDataθ, δdata::MacroDataδ )
#         θdata.πrj .= δdata.πrj      # yes, some duplication, but unclear how to avoid that without imposing other constraints
#         θdata.πj  .= δdata.πj
#         θdata.ρ   .= δdata.ρ
#     end
# end


# function MacroObjectiveθ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, Hδδ::Union{Matrix{T},Nothing}, Hδθ::Union{Matrix{T},Nothing}, data::MacroDataθ; recompute = true ) where {T<:Flt}
#     # This assumes choice probabilities and such have already been computed and reside in data
#     # Note that there is typically no point recomputing F since it was already computed in MacroObjectiveδ, but it isn't all that costly
#     ( Fδ,....... ) = GetMacroDataθ( data )
#     computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeHδδ = Hδδ ≠ nothing;  computeHδθ = Hδθ ≠ nothing;  computeH = computeHθθ || compute Hδθ
#     recompute &&  WeightedSum!( πj, w, πrj )
#     computeF && ( F -= sum( Ns[j] * log( πj[j] ) for j ∈ 1:J ) )

#     computeG || computeH || return F

#     WeightedDifference!( Δa, A, πrj )
#     WeightedSum!( ΣπA, w, πrj, Δa  )
#     recompute && ( ρ .= Ns ./ πj )
#     computeG && for k ∈ axes(G,1) G[k] -= sum( ρ[j] * ΣπA[j,k] for j ∈ axes(ρ) ) end 
#     computeH || return F
 
#     # now compute Hessian
#     WeightedSum2!( ρπ, ρ, πrj )    
#     ComputeΔ!( Δ, πrj )
#     if computeHθθ 
#         for t ∈ axes( Hθθ,2 )
#             for k ∈ 1:t
#                 for j ∈ axes(πrj,2)
#                     Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / πj[j]  + sum( w[r] * ( ρπ[r] - ρ[j] ) * πrj[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ axes(w,1) end
#                 end
#             end
#         end
#         Symmetrize!( Hθθ )
#     end
#     computeHδθ || return F
#     for t ∈ axes( Hδθ, 2 )
#         for k ∈ axes( Hδθ, 1 )
#             for j ∈ axes(ρ,1)
#                 Hδθ[ind] += sum( w[r] *  πrj[r,j] * (  ρ[j] * Δ[r,j,k] * ΣπA[j,t] / πj[j] + ( ρπ[j] - ρ[j] ) * πrj[r,j] * Δ[r,j,k] * Δa[r,j,t] ) for r ∈ axes(w,1)  )
#             end
#         end
#     end
#     F
# end





# function ObjectiveFunctionθStandard( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, fullθ::Vector{T}, 
#     microdata::MicroDataθ, macrodata::MacroDataθ, howtocomputeδ::Function ) where {T<:Flt}

    
#     ( δ, Fδ, Gδ, Hδ ) = howtocomputeδ( microdataδ, macrodataδ, startvecδ )
#     computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
#     computeG && ( G .= T(0.0) )
#     computeH && ( H .= T(0.0) )

#     FM = MacroObjectiveθ!( F, G, H, fullδ, macrodata )
#     Fm = MicroObjectiveθ!( F, G, H, fullδ, microdata )
#     computeF && ( F = Fm + FM )
#     F
# end


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

function RunIt()
    ( y, Y, Z, X, s, A, w, W, N ) = LoadIt("scratch1.jld") 
    println(s)
    ( S, J, dz ) = size( Z )
    R = length(w);  RM = length(W)
    dx = size(X,3);  dxz = dx + dz
    θ = ones( dxz )
    macrodata = MacroData( A, N * s, W )
    macrodata.Aθ .= [ dot( A[r,j,:], θ ) for r ∈ 1:RM, j ∈ 1:J ]
    θz = θ[1:dz];  θν = θ[dz+1:end]
    Ns = N * s
    microdata = MicroData( Z, X, y, w )
    microdata.ZXθ  .= [ dot( Z[i,j,:], θz ) + dot( X[r,j,:], θν ) for r ∈ 1:R, i ∈ 1:S, j ∈ 1:J ]
    println( 😠😠😠😠Standardδ( microdata, macrodata, zeros(J-1) ) )
end


RunIt()

