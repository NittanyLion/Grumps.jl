function GMMMoment1!( 
    mom         :: A1{T},
    momdθ       :: HType{T},
    momdδ       :: HType{T},
    θ           :: A1{T},
    δ           :: A1{T},
    md          :: GrumpsMarketData{T},
    𝒦m          :: AA2{T},
    o           :: OptimizationOptions,
    ms          :: GrumpsMarketSpace{T}
) where {T<:Flt}

    s,d = ms.microspace, md.microdata
    weights, consumers, products, insides, parameters = RSJ( d )
    dθz, dθν, dθ, J, dδ, S = dimθz( d ), dimθν( d ), dimθ( d ), dimJ( d ), dimδ( d ), dimS( d )

    demographics = 1:dθz
    rancos = 1:dθν

    B = d.ℳ               # instruments
    dmomb, dmomk = size( B, 3 ), size( 𝒦m, 2 )
    dmom = dmomb + dmomk

    @info "$(size(B)) $dmomb $dmomk $dmom $(size(mom,1))"
    @ensure dmom == size( mom, 1 )   "mismatch of the number of moments"


    moments, bmoments, kmoments = 1:dmom, 1:dmomb, 1:dmomk
 
    ChoiceProbabilities!( s, d, o, δ ) 

    πij = zeros( T, consumers[end], products[end] )
    @threads :dynamic for i ∈ consumers
        for j ∈ products
            πij[i,j] = sum( d.w[r] * s.πrij[r,i,j] for r ∈ weights )
        end
    end

    # first fill the moments
    mom .= zero( T )     
    @threads :dynamic for μ ∈ bmoments
        mom[ μ ] = sum( ( d.Y[i,j] - πij[i,j] ) * B[i,j,μ] for i ∈ consumers, j ∈ products )
    end
    for μ ∈ kmoments
        mom[ dmomb + μ ] = dot( 𝒦m[:,μ], δ )
    end

    
    if momdθ == nothing && momdδ == nothing
        return nothing
    end

    Δb =  𝓏𝓈( T, J, dθ )

    if momdθ ≠ nothing
        momdθ .= zero( T )
        for i ∈ consumers, r ∈ weights
            ComputeΔb!( Δb, s, d, o, r, i )
            for μ ∈ bmoments, v ∈ demographics
                momdθ[ μ, v ] -=  d.w[r] * sum( s.πrij[r,i,j] * B[i,j,μ] * Δb[j,v] for j ∈ products )
            end
        end
        # no derivatives of macro moments with respect to θ            
    end

    if momdδ == nothing
        return nothing
    end

    momdδ .= zero( T )
    Σππ = [ sum( d.w[r] * s.πrij[r,i,j] * s.πrij[r,i,k] for r ∈ weights ) for i ∈ consumers, j ∈ products, k ∈ products ]
    @threads :dynamic for μ ∈ bmoments
        for k ∈ insides
            for i ∈ consumers
                momdδ[μ,k] -= B[i,k,μ] * πij[ i, k ] - sum( Σππ[ i, j, k ] * B[i,j,μ] for j ∈ products )
            end
        end
    end
    @info "$(size(Km)) $(size(δ))"
    momdδ[dmomb+1:end,:] += T( 2.0 ) .*  𝒦m' * δ

    return nothing
end



function OutsideMoment1!(  
    fgh         :: GMMMarketFGH{T}, 
    θ           :: A1{T}, 
    δ           :: A1{T}, 
    e           :: GrumpsGMM, 
    d           :: GrumpsMarketData{T}, 
    𝒦m          :: AA2{T}, 
    o           :: OptimizationOptions, 
    ms          :: GrumpsMarketSpace{T}, 
    computeF    :: Bool, 
    computeG    :: Bool 
    ) where {T<:Flt}

    return GMMMoment1!( 
        fgh.mom,  
        grif( computeG || computeH, fgh.momdθ ),
        grif( computeG || computeH, fgh.momdδ ),
        θ,
        δ,
        d,
        𝒦m,
        o,
        ms
        )

end