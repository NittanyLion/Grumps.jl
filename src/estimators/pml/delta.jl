# @todo 4 "InsideObjective! needs to be redone for plm"


# struct Anything
# end

# AnyNothing = Union{Anything, Nothing}


# isanything( x ) =  typeof(x) == Anything

# ifanything( x, y) = isanything( x ) ? y : nothing


# this just computes the LLF and its δ derivatives for use with the Grumps estimator
# function  InsideObjective!( 
#     F       :: AnyNothing, 
#     G       :: AnyNothing, 
#     Hδδ     :: AnyNothing, 
#     Hδθ     :: AnyNothing,
#     fgh     :: GrumpsMarketFGH{T}
#     θ       :: Vec{T},
#     δ       :: Vec{ Vec{T} }, 
#     e       :: GrumpsPML, 
#     d       :: GrumpsData{T}, 
#     o       :: OptimizationOptions, 
#     s       :: GrumpsSpace{T} 
#     ) where {T<:Flt}
   
#     @ensure isanything( Hδθ ) == false  "cannot compute Hδθ here"

#     if F ≠ nothing
#         F .= zero( T )
#     end

#     markets = 1:dimM(d)
    
#     @threads :dynamic for m ∈ markets
#         local fullδ = vcat( δ[m], T(0.0) )

#         local memslot = memsave( o ) ?  AθZXθ!( θ, e, d.marketdata[m], o, s, m ) : m        

#         local fval = MacroObjectiveδ!( T(0.0),  
#             ifanything( G, fgh[m].inside.G ), 
#             ifanything( Hδδ, fgh[m].inside.Hδδ ), 
#             fullδ, data[m].macrodata, s.marketspace[memslot].macrospace, options; 
#             setzero = true 
#             )  
#         fval += MicroObjectiveδ!( T(0.0), 
#             ifanything( G, fgh[m].inside.G ), 
#             ifanything( Hδδ, fgh[m].inside.Hδδ ), 
#             fullδ, data[m].microdata, s.marketspace[memslot].microspace, options; 
#             setzero = false 
#             )  

#         if isanything( F )
#             fgh[m].inside.F .= fval
#         end

#         memsave( o ) &&  freeAθZXθ!( e, s, o, memslot )
#     end

#     return isnothing( F ) ? nothing : sum( fgh[m].insde.F for m ∈ markets )
# end
 

@info 2 "need to incorporate memory save mode here"


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
            true 
            )  
        fval += MicroObjectiveδ!( T(0.0), 
            easy( G, m ), 
            easy( H, m ), 
            δ[m], 
            d.marketdata[m].microdata, 
            s.marketspace[m].microspace, 
            o, 
            false 
            )  

        if !isnothing( F )
            Fm[m] = fval
        end

        mustrecompute( s ) &&  freeAθZXθ!( e, s, o, m )
    end

    return isnothing( F ) ? nothing : sum( Fm )
end
    