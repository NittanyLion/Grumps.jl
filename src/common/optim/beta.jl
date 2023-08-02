






function Computeβ!( sol :: GrumpsSolution{T}, δ :: Vec{T}, d :: GrumpsPLMData{T} ) where {T<:Flt} 
    β̂ = d.𝒳̂ \ δ
    for i ∈ eachindex( β̂ )
        sol.β[i].coef = β̂[i]
    end
    return nothing
end




Computeβ!( sol, δ, d :: GrumpsData{T} ) where {T<:Flt} = Computeβ!( sol, δ, d.plmdata )


function ComputeVξ!( sol :: GrumpsSolution{T}, δ :: Vec{T}, d :: GrumpsData{T} ) where {T<:Flt}
    β = getβcoef( sol )
    𝒳 = d.plmdata.𝒳
    ξ = δ - 𝒳 * β
    abs( mean( ξ ) ) < 1.0e-8 || @warn "ξ does not have a mean ≈ 0; did you include a constant in your regressors?  mean( ξ ) = $(mean(ξ))"
    r,c, = findnz( d.plmdata.template )
    if length( r ) > 0
        ξiξj  =  [ ξ[r[t]] * ξ[c[t]] for t ∈ eachindex( r ) ]
        sol.Vξ = sparse( r, c, ξiξj )
        return nothing
    end
    σξ2 = sum( ξ[i] * ξ[i] for i ∈ eachindex(ξ) ) / length( ξ )
    sol.Vξ = sparse( I * σξ2, length( ξ ), length( ξ ) )
    return nothing
end
