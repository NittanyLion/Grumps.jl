
@todo 1 "document this file"


function ExponentiationCorrection!( G :: AA1{T}, H :: HType{T}, θ :: AA1{T}, dθz :: Int ) where {T<:Flt}
    dθ = length( θ )
    for t ∈ dθz+1 : dθ
        G[t] *= θ[t]
    end
    if H ≠ nothing
        for t ∈ dθz+1 : dθ, k ∈ 1:dθ
            H[k,t] *= θ[t]
            H[t,k] *= θ[t]
        end
        for j ∈ dθz+1:dθ
            H[j,j] += G[j]
        end
    end
    return nothing
end
