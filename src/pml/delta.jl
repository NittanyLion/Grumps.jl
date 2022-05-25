@todo 4 "InsideObjective! needs to be redone for plm"


struct Anything
end

AnyNothing = Union{Anything, Nothing}


isanything( x ) =  typeof(x) == Anything

ifanything( x, y) = isanything( x ) ? y : nothing


# this just computes the LLF and its δ derivatives for use with the Grumps estimator

function  InsideObjective!( 
    F       :: AnyNothing, 
    G       :: AnyNothing, 
    Hδδ     :: AnyNothing, 
    Hδθ     :: AnyNothing,
    fgh     :: GrumpsMarketFGH{T}
    θ       :: Vec{T},
    δ       :: Vec{ Vec{T} }, 
    e       :: GrumpsPML, 
    d       :: GrumpsData{T}, 
    o       :: OptimizationOptions, 
    s       :: GrumpsSpace{T}, 
    m       :: Int = 0
    ) where {T<:Flt}
   
    @ensure isanything( Hδθ ) == false  "cannot compute Hδθ here"

    if F ≠ nothing
        F .= zero( T )
    end

    markets = 1:dimM(d)
    
    @threads :dynamic for m ∈ markets
        local fullδ = vcat( δ[m], T(0.0) )

        # now recompute choice probabilities if we are in memory save mode
        local memslot = memsave( o ) ?  AθZXθ!( θ, e, d.marketdata[m], o, s, m ) : m        

        local fval = MacroObjectiveδ!( T(0.0),  
            ifanything( G, fgh[m].inside.G ), 
            ifanything( Hδδ, fgh[m].inside.Hδδ ), 
            fullδ, data[m].macrodata, s.marketspace[memslot].macrospace, options; 
            setzero = true 
            )  
        fval += MicroObjectiveδ!( T(0.0), 
            ifanything( G, fgh[m].inside.G ), 
            ifanything( Hδδ, fgh[m].inside.Hδδ ), 
            fullδ, data[m].microdata, s.marketspace[memslot].microspace, options; 
            setzero = false 
            )  

        if isanything( F )
            fgh[m].inside.F .= fval
        end

        memsave( o ) &&  freeAθZXθ!( e, s, o, memslot )
    end

    return isnothing( F ) ? nothing : sum( fgh[m].insde.F for m ∈ markets )
end
    