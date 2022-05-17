

function computewhich( F :: FType{T}, G :: GType{T}, H :: HType{T} ) where {T<:Flt}
    return ( F ≠ nothing, G ≠ nothing, H ≠ nothing )
end 

function computewhich( F :: FType{T}, G :: GType{T}, H :: HType{T}, H2 :: HType{T} ) where {T<:Flt}
    return ( F ≠ nothing, G ≠ nothing, H ≠ nothing, H2 ≠ nothing )
end 


function SetZero!( setzero :: Bool, F :: FType{T}, G :: GType{T}, H :: HType{T}, Xtra :: HType{T} = nothing ) where {T<:Flt}
    setzero || return F 
    if F ≠ nothing 
        F = zero( T )
    end
    if G ≠ nothing
        G .= zero( T )
    end
    if H ≠ nothing
        H .= zero( T )
    end
    if Xtra ≠ nothing
        Xtra .= zero( T )
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