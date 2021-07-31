# The functions below pertain to the inner optimization loop.


# *******************  
# *                 *
# * Standard Grumps *
# *                 *
# *******************

function MacroObjectiveδ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, fullδ::Vector{T}, data::MacroData{T} ) where {T<:Flt}
    # initialize
    ( Ns, w, Aθ, πrj, πj, Σππ, ρ ) = GetMacroDataδ( data )  
    computeF =  F ≠ nothing ;  computeG =  G ≠ nothing;  computeH = H ≠ nothing

    # compute choice probabilties 
    ChoiceProbabilities!( πrj, Aθ, fullδ )
    WeightedSum!( πj, w, πrj )

    # compute objective function if desired
    computeF && ( F -= sum( Ns[j] * log( πj[j] ) for j ∈ eachindex(Ns) ) )
    computeG || computeH || return F            # nothing more to do if only F is to be computed

    WeightedSum!( Σππ, w, πrj, πrj )
    ρ .= Ns ./ πj

    # computing gradient if desired
    computeG && for k ∈ axes(G,1) G[k] -= ( Ns[k] - sum( ρ[j] * Σππ[j,k] for j ∈ eachindex(ρ) ) ) end
    computeH || return F                        
    
    for t ∈ axes( H, 2 ) 
        for k ∈ 1:t
            k == t &&  ( H[k,k] +=  sum( ρ[j] * w[r] * πrj[r,j] * πrj[r,k]  for r ∈ axes( πrj, 1), j ∈ axes( πrj, 2 )  ) )
            for j ∈ eachindex(ρ)
                H[k,t] += ρ[j] * Σππ[j,k] * Σππ[j,t] / πj[j] - 2.0 * ρ[j] * sum( w[r] * πrj[r,j] * πrj[r,k] * πrj[r,t] for r ∈ axes(πrj,1) )
            end
        end
    end
    Symmetrize!(H)
    F
end




function MicroObjectiveδ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, δ::Vector{T}, data::MicroData ) where {T<:Flt}
    # initialize
    ( y, Y, w, ZXθ, πrij, πri, πi, Σππ ) = GetMicroDataδ( data )
    computeF = F ≠ nothing; computeG = G ≠ nothing; computeH = H ≠ nothing
    
    # compute choice probabilities
    ChoiceProbabilities!( πrij, ZXθ, δ)
    Computeπri!( πri, πrij, y )
    WeightedSum!( πi, w, πri )

    computeF && ( F -= sum( log( πi[i] ) for i ∈ axes(πi,1) ) )
    computeG || computeH || return F

    # compute gradient
    WeightedSum!( Σππ, w, πri, πrij )
    computeG && for k ∈ axes(G,1) G[k] -= sum( Y[i,k] - Σππ[i,k] / πi[i] for i ∈ axes(Y,1) ) end
    computeH || return F

    # compute Hessian
    for t ∈ axes( H, 2 )
        for k ∈ 1:t
            k == t && ( H[k,t] +=  sum( Σππ[i,t] / πi[i] for i ∈ axes(πi,1) ) )
            for i ∈ axes(Σππ,1)
                H[k,t] += Σππ[i,k] * Σππ[i,t] / πi[i]^2 - 2.0 * sum( w[r] * πri[r,i] * πrij[r,i,k] * πrij[r,i,t] for r ∈ axes(w,1) )  / πi[i]
            end
        end
    end
    Symmetrize!( H )
    F 
end



function ObjectiveFunctionδStandard!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T}, Nothing}, fullδ::Vector{T},  microdata::MicroData, macrodata::MacroData ) where {T<:Flt}

    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
    computeG && ( G .= T(0.0) )
    computeH && ( H .= T(0.0) )

    FM = MacroObjectiveδ!( F, G, H, fullδ, macrodata )
    Fm = MicroObjectiveδ!( F, G, H, fullδ, microdata )
    computeF && ( F = Fm + FM )
    F
end



# computes optimal δ for a given θ where the values of θ are already embedded in microdata and macrodata
# this is standard grumps
function 😠😠😠😠Standardδ!( results::Resultsδ{T}, microdata::MicroData, macrodata::MacroData, startvec::Vector{T} ) where {T<:Flt}
    Ωδ!(  F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, δ::Vector{T} ) where {T<:Flt} =
        ObjectiveFunctionδStandard!( F, G, H, vcat( δ, T(0.0) ), microdata, macrodata )   

    res = optimize(Optim.only_fgh!(Ωδ!), startvec, NewtonTrustRegion(), Optim.Options(show_trace=false, extended_trace=true, x_tol=0.0, g_tol=1.0e-8, iterations=50 ) )
    results.δ .= res.minimizer
    results.F .= Ωδ!( T(0.0), results.Gδ, results.Hδδ, results.δ )
    results
end


GrumpsStandardδ! = 😠😠😠😠Standardδ!






# *************  
# *           *
# * SC Grumps *
# *           *
# *************


function ObjectiveFunctionδSC!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T}, Nothing}, fullδ::Vector{T}, macrodata::MacroData ) where {T<:Flt}
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
    computeG && ( G .= T(0.0) )
    computeH && ( H .= T(0.0) )
    FM = MacroObjectiveδ!( F, G, H, fullδ, macrodata )
    computeF ? FM : F
end



function 😠😠😠😠SCδ!( results::Resultsδ{T}, macrodata::MacroData, startvec::Vector{T} ) where {T<:Flt}
    Ωδ!(  F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, δ::Vector{T} ) where {T<:Flt} =
        ObjectiveFunctionδSC!( F, G, H, vcat( δ, T(0.0) ), macrodata )   

    res = optimize(Optim.only_fgh!(Ωδ!), startvec, NewtonTrustRegion(), Optim.Options(show_trace=true, extended_trace=true, x_tol=0.0, g_tol=1.0e-8, iterations=50 ) )
    results.δ .= res.minimizer
    results.F .= Ωδ!( T(0.0), results.Gδ, results.Hδδ, results.δ )
    display(results); exit()
    results
end





