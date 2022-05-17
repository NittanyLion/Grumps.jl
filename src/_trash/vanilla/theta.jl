

"""
OutsideObjective1!(  
    fgh         :: GrumpsSingleFGH{T}, 
    θ           :: Vec{T},
    δ           :: Vec{T},
    e           :: GrumpsMixedLogitEstimator, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions, 
    s           :: GrumpsMarketSpace{T}, 
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
    e           :: GrumpsVanillaEstimator, 
    d           :: GrumpsMarketData{T}, 
    o           :: OptimizationOptions, 
    s           :: GrumpsMarketSpace{T}, 
    computeF    :: Bool, 
    computeG    :: Bool, 
    computeH    :: Bool 
    ) where {T<:Flt}


    F1 = MacroObjectiveθ!( 
        grif( computeF, fgh.F[1] ),
        grif( computeG, fgh.Gθ ),
        grif( computeH, fgh.Hθθ ),
        grif( computeH, fgh.Hδθ ),
        θ,
        δ,
        d.macrodata,
        s.macrospace,
        o,
        true
         ) 

    F2 = MicroObjectiveθ!( 
        F1,
        grif( computeG, fgh.Gθ ),
        grif( computeH, fgh.Hθθ ),
        grif( computeH, fgh.Hδθ ),
        θ,
        δ,
        d.microdata,
        s.microspace,
        o,
        false
        ) 
    
    if computeF
        fgh.F .= F2
    end

    return F2
end
