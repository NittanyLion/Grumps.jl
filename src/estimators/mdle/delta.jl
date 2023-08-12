function  InsideObjective1!( 
    F       :: FType{T}, 
    G       :: GType{T}, 
    Hδδ     :: HType{T}, 
    Hδθ     :: HType{T},
    θ       :: Vec{T},
    δ       :: Vec{T}, 
    e       :: GrumpsMDLEEstimator, 
    d       :: GrumpsMarketData{T}, 
    o       :: OptimizationOptions, 
    s       :: GrumpsMarketSpace{T}, 
    m       :: Int = 0
    ) :: FType{T} where {T<:Flt} 
    
    F1 :: typeof( F ) = MacroObjectiveδ!( 
        F,
        G,
        Hδδ,
        δ,
        macrodata( d ),
        macrospace( s ),
        o,
        m,
        true
         ) 
     
    F2 :: typeof( F ) =  MicroObjectiveδ!( 
        F1,
        G,
        Hδδ,
        δ,
        microdata( d ),
        microspace( s ),
        o,
        m,
        false               # this is to indicate that things shouldn't be set to zero
         ) 

    
    return F2
end