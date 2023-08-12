

"""
OutsideObjective1!(  
    fgh         :: GrumpsSingleFGH{T}, 
    θ           :: Vec{T},
    δ           :: Vec{T},
    e           :: GrumpsMixedLogitEstimator, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions, 
    s           :: GrumpsMarketSpace{T}, 
    m           :: Int,
    computeF    :: Bool, 
    computeG    :: Bool, 
    computeH    :: Bool 
    )

Outside single market objective function for the Mixed Logit Estimator.  
Since the inside and outside objective functions coincide there is no
reason to recompute Ωδδ, Ωδθ
"""
function  OutsideObjective1!(  
    fgh         :: GrumpsSingleFGH{T}, 
    θ           :: Vec{T},
    δ           :: Vec{T},
    e           :: GrumpsMDLEEstimator, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions, 
    s           :: GrumpsMarketSpace{T}, 
    m           :: Int,
    computeF    :: Bool, 
    computeG    :: Bool, 
    computeH    :: Bool 
    ) :: Union{ Nothing, T } where {T<:Flt} 


    F1 :: Union{ Nothing, T } = MacroObjectiveθ!( 
        grif( computeF, fgh.F[1] ),
        grif( computeG, fgh.Gθ ),
        grif( computeH, fgh.Hθθ ),
        grif( computeH, fgh.Hδθ ),
        θ,
        δ,
        d.macrodata,
        s.macrospace,
        o,
        m,
        true
         ) 

    F2 :: Union{ Nothing, T } = MicroObjectiveθ!( 
        F1,
        grif( computeG, fgh.Gθ ),
        grif( computeH, fgh.Hθθ ),
        grif( computeH, fgh.Hδθ ),
        θ,
        δ,
        d.microdata,
        s.microspace,
        o,
        m,
        false
        ) 
    
    if computeF
        fgh.F .= F2
    end

    return F2
end
