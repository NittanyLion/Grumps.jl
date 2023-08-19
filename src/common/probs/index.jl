

FillAθ!( θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroNoData{T}, o :: OptimizationOptions, s :: GrumpsMacroSpace{T}  ) where {T<:Flt} = nothing
FillAθ!( θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroNoData{T}, o :: OptimizationOptions, s :: GrumpsMacroNoSpace{T}  ) where {T<:Flt} = nothing

function FillAθ!( id :: Any, θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions, s :: GrumpsMacroSpace{T}  ) where {T<:Flt}
    isdefined( Main, :InteractionsCallback! ) && return FillAθ!( Val( :GrumpsInteractions! ), θ, e, d, o, s ) 
    isdefined( Main, :InteractionsCallback ) && return FillAθ!( Val( :GrumpsInteractions ), θ, e, d, o, s ) 
    weights, products, insides, parameters = RJ( d )

    @tullio fastmath=false s.Aθ[r,j] = d.𝒟[r,t] * d.𝒳[j,t] * θ[t]

    return nothing
end

function FillAθ!( ::Val{ :GrumpsInteractions }, θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions, s :: GrumpsMacroSpace{T} ) where {T<:Flt}
    weights, products, insides, parameters = RJ( d )
    for r ∈ weights, j ∈ products
        s.Aθ[r,j] = sum( Main.InteractionsCallback( d.𝒟, d.𝒳, r, j, t, :macro, d.name, String[]  ) * θ[t] for t ∈ parameters )
    end
end



function FillAθ!( ::Val{ :GrumpsInteractions! }, θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions, s :: GrumpsMacroSpace{T} ) where {T<:Flt}
    Main.InteractionsCallback!( s.Aθ, d.𝒟, d.𝒳, θ, :macro, d.name, String[]  ) 
end


FillAθ!( θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions, s :: GrumpsMacroSpace{T}  ) where {T<:Flt} = FillAθ!( Val( id( o ) ), θ, e, d, o, s )




FillZXθ!(  θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMicroNoData{T}, o :: OptimizationOptions, s :: GrumpsMicroSpace{T}  ) where {T<:Flt} = nothing
FillZXθ!(  θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMicroNoData{T}, o :: OptimizationOptions, s :: GrumpsMicroNoSpace{T}  ) where {T<:Flt} = nothing


function FillZXθ!(  :: Any, θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMicroDataHog{T}, o :: OptimizationOptions, s :: GrumpsMicroSpace{T}  ) where {T<:Flt}
    for r ∈ axes( s.ZXθ, 1 )
        @tullio fastmath=false s.ZXθ[$r,i,j] = d.Z[i,j,t] * θ[t+0]
    end
    dθz = dimθz( d ) :: Int
    for i ∈ axes( s.ZXθ, 2)
        @tullio fastmath=false s.ZXθ[r,$i,j] += d.X[r,j,t] * θ[t+$dθz]
    end
    return nothing
end

function FillZXθ!(  :: Any, θ :: Vector{T}, e :: GrumpsEstimator, d :: MSMMicroDataHog{T}, o :: OptimizationOptions, s :: GrumpsMicroSpace{T}  ) where {T<:Flt}
    @threads :dynamic for i ∈ 1:dimS( d )
        for r ∈ 1:dimR( d ), j ∈ 1:dimJ( d )
            s.ZXθ[r,i,j] = sum( d.Z[i,j,t] * θ[t] for t ∈ 1:dimθz( d ) ) + sum( d.X[r,i,j,t] * θ[ t+ dimθz( d ) ] for t ∈ 1:dimθν( d ) )
        end
    end
    return nothing
end

FillZXθ!(  θ :: Vector{T}, e :: GrumpsEstimator, d, o :: OptimizationOptions, s :: GrumpsMicroSpace{T}  ) where {T<:Flt} = FillZXθ!( Val( id( o ) ), θ, e, d, o, s )


function SoftmaxZXθ!( ms :: GrumpsMicroSpace{T}, R :: Int, S :: Int ) where {T<:Flt}
    @threads :dynamic for r ∈ 1:R
        for i ∈ 1:S 
            softmax!( @view ms.ZXθ[ r, i, :] )
        end
    end
end

SoftmaxZXθ!( ms :: GrumpsMicroNoSpace{T}, R :: Int, S :: Int ) where {T<:Flt} = nothing



function SoftmaxAθ!( ms :: GrumpsMacroSpace{T}, R :: Int ) where {T<:Flt}
    @threads :dynamic for r ∈ 1:R
        softmax!( @view ms.Aθ[ r, :] )
    end
end

SoftmaxAθ!( ms :: GrumpsMacroNoSpace{T}, R :: Int ) where {T<:Flt} = nothing


function AθZXθ!( 
    θ :: Vec{T}, 
    e :: GrumpsEstimator, 
    d :: GrumpsMarketData{T}, 
    o :: OptimizationOptions, 
    s :: GrumpsSpace{T}, 
    m :: Int 
    ) where {T<:Flt}

    sm = marketspace( s, m )

    acquire( s.semas, sm.memblockindex )
    

    FillAθ!( θ, e, d.macrodata, o, sm.macrospace )
    FillZXθ!( θ, e, d.microdata, o, sm.microspace )

    if probtype( o ) == :robust
        @ensure false "robust choice probabilities have not yet been implemented"
        return nothing
    end
    
    @ensure probtype( o ) == :fast "unknown choice probability type $(probtype(o))"
    
    SoftmaxAθ!( sm.macrospace, dimR( d.macrodata ) )
    SoftmaxZXθ!( sm.microspace, dimR( d.microdata ), dimS( d.microdata ) )

    
    return m
end


function freeAθZXθ!( e :: GrumpsEstimator, s :: GrumpsSpace{T}, o :: OptimizationOptions, m :: Int ) where {T<:Flt}
    release( s.semas, s.marketspace[m].memblockindex )
    return nothing
end