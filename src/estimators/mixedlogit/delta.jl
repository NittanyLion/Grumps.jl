
function  InsideObjective1!( 
    F       :: FType{T}, 
    G       :: GType{T}, 
    Hδδ     :: HType{T}, 
    Hδθ     :: HType{T},
    θ       :: Vec{T},
    δ       :: Vec{T}, 
    e       :: GrumpsMixedLogitEstimator, 
    d       :: GrumpsMarketData{T}, 
    o       :: OptimizationOptions, 
    s       :: GrumpsMarketSpace{T}, 
    m       :: Int = 0
    ) where {T<:Flt}
    
    rv = MicroObjectiveδ!( 
        F,
        G,
        Hδδ,
        δ,
        d.microdata,
        s.microspace,
        o,
        m,
        true
         ) 
         
    return rv
end