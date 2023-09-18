

function computewhich( F, G, H ) 
    return ( F ≠ nothing, G ≠ nothing, H ≠ nothing )
end 

function computewhich( F, G, H, H2 ) 
    return ( F ≠ nothing, G ≠ nothing, H ≠ nothing, H2 ≠ nothing )
end 


function SetZero!( setzero :: Bool, F, G, H, Xtra :: Any = nothing ) 
    setzero || return F 
    if F ≠ nothing 
        F = zero( F )
    end
    if G ≠ nothing
        G .= zero( G )
    end
    if H ≠ nothing
        H .= zero( H )
    end
    if Xtra ≠ nothing
        Xtra .= zero( Xtra )
    end
    return F
end

grif( cond :: Bool, something :: T ) where T = cond ? something : nothing
 
function getθ( θtransformed :: Vector{T}, d :: GrumpsData{T} ) where {T<:Flt}
    dz = dimθz(d)
    if dz == 0
        return exp.( θtransformed )
    end
    if dimθν( d ) == 0
        return θtransformed
    end
    return vcat( θtransformed[  1 : dz ], exp.( θtransformed[ dz + 1 : dimθ(d) ] ) )
end