

FillAθ!( θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroNoData{T}, o :: OptimizationOptions, s :: GrumpsMacroSpace{T}  ) where {T<:Flt} = nothing
FillAθ!( θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroNoData{T}, o :: OptimizationOptions, s :: GrumpsMacroNoSpace{T}  ) where {T<:Flt} = nothing

function FillAθ!( θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMacroDataAnt{T}, o :: OptimizationOptions, s :: GrumpsMacroSpace{T}  ) where {T<:Flt}
    weights, products, insides, parameters = RJ( d )
    @threads :dynamic for r ∈ weights
        for j ∈ products
            s.Aθ[r,j] = sum( d.𝒟[r,t] * d.𝒳[j,t] * θ[t] for t ∈ parameters )
        end
    end
    return nothing
end

FillZXθ!(  θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMicroNoData{T}, o :: OptimizationOptions, s :: GrumpsMicroSpace{T}  ) where {T<:Flt} = nothing
FillZXθ!(  θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMicroNoData{T}, o :: OptimizationOptions, s :: GrumpsMicroNoSpace{T}  ) where {T<:Flt} = nothing


function FillZXθ!(  θ :: Vector{T}, e :: GrumpsEstimator, d :: GrumpsMicroDataHog{T}, o :: OptimizationOptions, s :: GrumpsMicroSpace{T}  ) where {T<:Flt}
    @threads :dynamic for i ∈ 1:dimS( d )
        for r ∈ 1:dimR( d ), j ∈ 1:dimJ( d )
            s.ZXθ[r,i,j] = sum( d.Z[i,j,t] * θ[t] for t ∈ 1:dimθz( d ) ) + sum( d.X[r,j,t] * θ[ t+ dimθz( d ) ] for t ∈ 1:dimθν( d ) )
        end
    end
    return nothing
end

function FillZXθ!(  θ :: Vector{T}, e :: GrumpsEstimator, d :: MSMMicroDataHog{T}, o :: OptimizationOptions, s :: GrumpsMicroSpace{T}  ) where {T<:Flt}
    @threads :dynamic for i ∈ 1:dimS( d )
        for r ∈ 1:dimR( d ), j ∈ 1:dimJ( d )
            s.ZXθ[r,i,j] = sum( d.Z[i,j,t] * θ[t] for t ∈ 1:dimθz( d ) ) + sum( d.X[r,i,j,t] * θ[ t+ dimθz( d ) ] for t ∈ 1:dimθν( d ) )
        end
    end
    return nothing
end

function AθZXθ!( 
    θ :: Vec{T}, 
    e :: GrumpsEstimator, 
    d :: GrumpsMarketData{T}, 
    o :: OptimizationOptions, 
    s :: GrumpsSpace{T}, 
    m :: Int 
    ) where {T<:Flt}

    sm = s.marketspace[m]

    acquire( s.semas, sm.memblockindex )
    


    FillAθ!( θ, e, d.macrodata, o, sm.macrospace )
    FillZXθ!( θ, e, d.microdata, o, sm.microspace )

    if probtype( o ) == :robust
        @ensure false "robust choice probabilities have not yet been implemented"
        return nothing
    end
    
    @ensure probtype( o ) == :fast "unknown choice probability type $(probtype(o))"
    
    @threads :dynamic for r ∈ 1:dimR( d.macrodata )
        softmax!( @view sm.macrospace.Aθ[ r, :] )
    end    
    
    @threads :dynamic for r ∈ 1:dimR( d.microdata )
        for i ∈ 1:dimS( d.microdata ) 
            softmax!( @view sm.microspace.ZXθ[ r, i, :] )
        end
    end
    
    
    return m
end


function freeAθZXθ!( e :: GrumpsEstimator, s :: GrumpsSpace{T}, o :: OptimizationOptions, m :: Int ) where {T<:Flt}
    release( s.semas, s.marketspace[m].memblockindex )
    return nothing
end