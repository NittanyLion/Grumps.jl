function GMMMoment1!( 
    mom         :: A1{T},
    dmomθ       :: HType{T},
    dmomδ       :: HType{T},
    θ           :: A1{T},
    δ           :: A1{T},
    d           :: GrumpsMarketData{T},
    𝒦m          :: AA2{T},
    o           :: OptimizationOptions,
    ms          :: GrumpsMarketSpace{T}
)


    B = d.microdata.ℳ               # instruments
    dmomb = size( B, 3 )
    dmomk = size( 𝒦m, 2 )
    @ensure dmomb + dmomk == size( mom, 1 )   "mismatch of the number of moments"

    
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
    )

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