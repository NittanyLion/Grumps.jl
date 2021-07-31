# The code below creates the data structures, constructors, related functions,
# and conversion functions.


Flt = AbstractFloat


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
    Δb   :: Array{T,4}      # intermediate object  (R,S,J,dθ)                               θ               ( will hopefully be reduced in size or go away )
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



struct Resultsδ{T<:Flt}
    δ   ::  Vector{T}
    F   ::  Vector{T}
    Gδ  ::  Vector{T}
    Hδδ ::  Matrix{T}
    Hδθ ::  Union{ Matrix{T}, Nothing }

    function Resultsδ( T2::Type, J :: Int, estimator = :Standard, dθ = 0 ) 
        dδ = J - 1
        estimator == :Standard && return new{T2}( zeros(T2,dδ), [ 0.0 ], zeros(T2,dδ), zeros(T2,dδ,dδ), nothing )
        estimator == :SC &&  return new{T2}( zeros(T2,dδ), [ 0.0 ], zeros(T2,dδ), zeros(T2,dδ,dδ), zeros(T2, dδ, dθ) )
    end
end




struct Resultsθ{T<:Flt}
    F   :: Vector{T}      #  (1)     objective function value
    G   :: Vector{T}      #  (dθ)    gradient
    Hθθ :: Matrix{T}      #  (dθ,dθ) Hessian
    Hδθ :: Matrix{T}      #  (dδ,dθ) part of the larger Hessian
    Hδδ :: Union{Matrix{T},Nothing}   # only needed for SC
    function Resultsθ( T2::Type, dθ::Int, J::Int, estimator = :Standard ) 
        estimator == :Standard && return  new{T2}( zeros(T2,1), zeros(T2,dθ), zeros(T2,dθ,dθ), zeros(T2,J-1,dθ), nothing )
        estimator == :SC  && return new{T2}( zeros(T2,1), zeros(T2,dθ), zeros(T2,dθ,dθ), zeros(T2,J-1,dθ), zeros(T2, J-1, J-1) )
    end
end



struct Resultsδθ{T<:Flt}
    resultsδ :: Resultsδ{T}
    resultsθ :: Resultsθ{T}
    function Resultsδθ( data::MarketData{T2}, estimator = :Standard ) where {T2<:Flt}
        (R,J,dθ) = size( data.macrodata.A )
        new{T2}( Resultsδ( T2, J, estimator, dθ ), Resultsθ( T2, dθ, J, estimator ) )
    end
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
    start = 1;  
    for m ∈ eachindex(resultsδθ)  
        range = start: start+dδ[m]-1
        results.δ[ range ] = resultsδθ[m].resultsδ.δ 
        results.Hθθ .+= resultsδθ[m].resultsθ.Hθθ 
        results.Hδθ[range,:] .= resultsδθ[m].resultsθ.Hδθ 
        results.Hδδ[range,range] = resultsδθ[m].resultsδ.Hδδ 
        start += dδ[m]
    end
    results
end


