function  InsideObjective1!( 
    F       :: FType{T}, 
    G       :: GType{T}, 
    Hδδ     :: HType{T}, 
    Hδθ     :: HType{T},
    θ       :: Vec{T},
    δ       :: Vec{T}, 
    e       :: GrumpsGMM, 
    d       :: GrumpsMarketData{T}, 
    o       :: OptimizationOptions, 
    s       :: GrumpsMarketSpace{T}, 
    m       :: Int = 0
    ) where {T<:Flt}
    
    F1 = MacroObjectiveδ!( 
        F,
        G,
        Hδδ,
        δ,
        d.macrodata,
        s.macrospace,
        o,
        m,
        true
         ) 

    # now pick up Hδθ to construct dδθ
    if Hδθ ≠ nothing
        MacroObjectiveθ!(
            nothing,
            nothing,
            nothing,
            Hδθ, 
            θ,
            δ,
            d.macrodata, 
            s.macrospace,
            o,
            m,
            true 
        )
    end

    return F1
end