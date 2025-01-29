



function easy( x, m )
    if x == nothing return nothing end
    if typeof( x ) <: Vector
        @ensure (1 ≤ m ≤ length( x ))  "element out of bounds"
        return x[m]
    end
    @ensure false "not a vector"
end


function InsideObjective!( 
    F       :: FType{T}, 
    G       :: GVType{T}, 
    H       :: HVType{T}, 
    θ       :: Vec{T},
    δ       :: Vec{ Vec{T} }, 
    e       :: GrumpsPenalized, 
    d       :: GrumpsData{T}, 
    o       :: OptimizationOptions, 
    s       :: GrumpsSpace{T}
    ) where {T<:Flt}
   

    markets = 1:dimM(d)
    Fm = zeros( dimM(d) )

    @threads :dynamic for m ∈ markets

        mustrecompute(s) && AθZXθ!( θ, e, d.marketdata[m], o, s, m ) 

        local fval = MacroObjectiveδ!( T(0.0),  
            easy( G, m ), 
            easy( H, m ), 
            δ[m], 
            d.marketdata[m].macrodata, 
            s.marketspace[m].macrospace, 
            o,
            m,
            true 
            )  
        fval += MicroObjectiveδ!( T(0.0), 
            easy( G, m ), 
            easy( H, m ), 
            δ[m], 
            d.marketdata[m].microdata, 
            s.marketspace[m].microspace, 
            o, 
            m,
            false 
            )  

        if !isnothing( F )
            Fm[m] = fval
        end

        mustrecompute( s ) &&  freeAθZXθ!( e, s, o, m )
    end

    return isnothing( F ) ? nothing : sum( Fm )
end
    