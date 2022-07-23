@todo 3 "too much garbage collection for gmm"

function GMMMoment1!( 
    mom         :: A1{T},
    momdθ       :: HType{T},
    momdδ       :: HType{T},
    θ           :: A1{T},
    δ           :: A1{T},
    d           :: GrumpsMicroData{T},
    𝒦m          :: AA2{T},
    o           :: OptimizationOptions,
    s           :: GrumpsMicroSpace{T}
) where {T<:Flt}

    # s,d = ms.microspace, md.microdata
    weights, consumers, products, insides, parameters = RSJ( d )
    dθz, dθν, dθ, J, dδ, S = dimθz( d ), dimθν( d ), dimθ( d ), dimJ( d ), dimδ( d ), dimS( d )


    B = d.ℳ               # instruments
    dmomb, dmomk = size( B, 3 ), size( 𝒦m, 2 )
    dmom = dmomb + dmomk

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
        mom[ μ ] = sum( ( d.Y[i,j] - πij[i,j] ) * B[i,j,μ] for i ∈ consumers, j ∈ insides )
    end
    for μ ∈ kmoments
        mom[ dmomb + μ ] = dot( 𝒦m[:,μ], δ )
    end

    
    if momdθ == nothing && momdδ == nothing
        return nothing
    end

    Δb =  zeros( T, J, dθ )

    if momdθ ≠ nothing
        momdθ .= zero( T )
        for i ∈ consumers, r ∈ weights
            ComputeΔb!( Δb, s, d, o, r, i )
            for μ ∈ bmoments, v ∈ parameters, j ∈ insides
                momdθ[ μ, v ] -=  d.w[r] * s.πrij[r,i,j] * B[i,j,μ] * Δb[j,v] 
            end
        end
        # no derivatives of macro moments with respect to θ            
    end

    if momdδ == nothing
        return nothing
    end

    momdδ .= zero( T )
    @threads :dynamic for μ ∈ bmoments
        for k ∈ insides
            for i ∈ consumers
                momdδ[μ,k] -= ( B[i,k,μ] * πij[ i, k ] -
                   sum( d.w[r] * s.πrij[r,i,j] * s.πrij[r,i,k] * B[i,j,μ] for j ∈ insides, r ∈ weights ) )
            end
        end
    end

    momdδ[dmomb+1:end,:] +=   𝒦m'  

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
        grif( computeG, fgh.momdθ ),
        grif( computeG, fgh.momdδ ),
        θ,
        δ,
        d.microdata,
        𝒦m,
        o,
        ms.microspace
        )

end