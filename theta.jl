# The functions below pertain to the outer optimization loop.




# *******************  
# *                 *
# * Standard Grumps *
# *                 *
# *******************


function MacroObjectiveθ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, Hθθ::Union{Matrix{T},Nothing}, Hδθ::Union{Matrix{T},Nothing}, θ::Vector{T}, data::MacroData ) where {T<:Flt}
    # This assumes choice probabilities and such have already been computed and reside in data
    # Note that there is typically no point recomputing F since it was already computed in MacroObjectiveδ, but it isn't all that costly
    ( A, Ns, w, πrj, πj, ρ, Δa, Δ, ΣπA, ρπ ) = GetMacroDataθ( data )
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeHθθ = Hθθ ≠ nothing;  computeHδθ = Hδθ ≠ nothing;  computeH = computeHθθ || computeHδθ
 
    computeF && ( F -= sum( Ns[j] * log( πj[j] ) for j ∈ 1:J ) )
    computeG || computeH || return F

    WeightedDifference!( Δa, A, πrj )
    WeightedSum!( ΣπA, w, πrj, Δa  )
    computeG && for k ∈ eachindex(G) G[k] -= sum( ρ[j] * ΣπA[j,k] for j ∈ eachindex(ρ) ) end 
    computeH || return F
 
    # now compute Hessian
    WeightedSum2!( ρπ, ρ, πrj )    
    ComputeΔ!( Δ, πrj )
    if computeHθθ 
        for t ∈ axes( Hθθ,2 )
            for k ∈ 1:t
                for j ∈ axes(πrj,2)
                    Hθθ[k,t] += ρ[j] * ΣπA[j,k] * ΣπA[j,t] / πj[j]  + sum( w[r] * ( ρπ[r] - ρ[j] ) * πrj[r,j] * Δa[r,j,k] * Δa[r,j,t] for r ∈ eachindex(w) )
                end
            end
        end
        Symmetrize!( Hθθ )
    end
    computeHδθ || return F
    for t ∈ axes( Hδθ, 2 )
        for k ∈ axes( Hδθ, 1 )
            for j ∈ eachindex(ρ)
                Hδθ[k,t] += sum( w[r] *  πrj[r,j] * Δ[r,j,k] * (  ρ[j]  * ΣπA[j,t] / πj[j] + ( ρπ[r] - ρ[j] )  * Δa[r,j,t] ) for r ∈ eachindex(w)  )
            end
        end
    end
    F
end


function MicroObjectiveθ!( F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, Hθθ::Union{Matrix{T},Nothing}, Hδθ::Union{Matrix{T},Nothing}, θ::Vector{T}, data::MicroData ) where {T<:Flt}
    ( Z, X, y, Y, w, πrij, πri, πi, Σπb, Δb ) = GetMicroDataθ( data )
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeHθθ = Hθθ ≠ nothing;  computeHδθ = Hδθ ≠ nothing;  computeH = computeHθθ || computeHδθ
 
    computeF && ( F -= sum( log( πi[i] ) for i ∈ eachindex( πi ) ) )
    computeG || computeH || return F

    for i ∈ axes( Z, 1 )
        for r ∈ eachindex( w )
            for k ∈ axes( Z, 3 ) 
                avg = sum( πrij[r,i,v] * Z[i,v,k] for v ∈ axes( Z, 2 ) )
                for j ∈ axes(Z,2) #( computeH ? axes( Z,2 ) : y[i] )
                    Δb[r,i,j,k] = Z[i,j,k] - avg 
                end
            end
            for k ∈ axes( X, 3 )
                avg = sum( πrij[r,i,v] * X[r,v,k] for v ∈ axes( X, 2 ) )
                for j ∈ axes(X,2) #( computeH ? axes( X, 2) : y[i] )
                    Δb[r,i,j,k + size(Z,3) ] = X[r,j,k] - avg
                end
            end
        end
    end
    for k ∈ axes( Σπb, 2 )
        for i ∈ axes( Σπb, 1 )
            Σπb[i,k] = sum( w[r] * πri[r,i] * Δb[r,i,y[i],k] for r ∈ eachindex( w ) )
        end
    end

    computeG &&  for k ∈ axes( Σπb,2 )  G[k] -= sum( Σπb[i,k] / πi[i] for i ∈ axes( Σπb, 1 ) ) end
    computeH || return F

    if computeHθθ 
        for t ∈ axes( Hθθ,2 )
            for k ∈ 1:t
                for i ∈ axes( Σπb, 1 )
                    Hθθ[k,t] += Σπb[i,k] * Σπb[i,t] / πi[i]^2
                    for j ∈ axes( Y, 2 )
                        Hθθ[k,t] += sum( w[r] * ( πri[r,i] - Y[i,j] ) * πrij[r,i,j] * Δb[r,i,j,k] * Δb[r,i,j,t] for r ∈ eachindex(w) ) / πi[i]
                    end
                end
            end
        end
        Symmetrize!( Hθθ )
    end
    computeHδθ || return F

    for t ∈ axes(Hδθ, 2)
        for k ∈ axes(Hδθ, 1)
            for i ∈ axes( Σπb, 1)
                Hδθ[k,t] += sum( w[r] * πri[r,i] * πrij[r,i,k] *  ( ( Δb[r,i,y[i],t] + Δb[r,i,k,t] ) / πi[i] -  Σπb[i,t] / πi[i]^2 ) for r ∈ eachindex(w) )
            end
        end
    end
    F
end    


function ExponentiationCorrection!( G::Union{Vector{T}, Nothing}, Hθθ::Union{Matrix{T}, Nothing}, Hδθ::Union{Matrix{T}, Nothing}, θ::Vector{T}, start::Int ) where {T<:Flt}
    G == nothing || for t ∈ start : length( θ ) G[t] *= θ[t]  end 
    Hδθ == nothing || for t ∈ start:length(θ) Hδθ[:,t] *= θ[t] end
    Hθθ == nothing && return
    for t ∈ start:length(θ)
        Hθθ[t,:] *= θ[t]
        Hθθ[:,t] *= θ[t]
    end
    Hθθ == nothing && return
    G == nothing && throw( ArgumentError("💩 Cannot compute Hθθ without G due to exponentiation issue 💩") )
    for t ∈ start:length(θ)  Hθθ[t,t] += G[t] end
    nothing
end


function ObjectiveFunctionθStandardOneMarket!( resultsθ::Resultsθ{T}, resultsδ::Resultsδ{T}, computeF::Bool, computeG::Bool, computeH::Bool, θ::Vector{T}, microdata::MicroData{T}, macrodata::MacroData{T} ) where {T<:Flt}

    # first calculate δ
    # these constructors might be slow; should check
    dz = size( microdata.Z, 3);  dθ = size( macrodata.A, 3 )
    macrodata.Aθ[:,:] = [ sum( macrodata.A[r,j,t] * θ[t] for t ∈ 1:dθ ) for r ∈ axes( macrodata.A, 1 ), j ∈ axes( macrodata.A, 2 ) ]    
    microdata.ZXθ[:,:,:] =  [ sum( microdata.Z[i,j,t] * θ[t] for t ∈ 1:dz ) + sum( microdata.X[r,j,t] * θ[dz+t] for t ∈ 1:dθ-dz ) for r ∈ axes( microdata.X, 1), i ∈ axes( microdata.Z, 1 ), j ∈ axes( microdata.X, 2 ) ]
    😠😠😠😠Standardδ!( resultsδ, microdata, macrodata, zeros( T, size( macrodata.A, 2  ) - 1  ) )         # compute δ for given θ   
    resultsθ.F .= resultsδ.F

    # return if no derivatives are needed
    computeG || computeH || return 

    # now initialize the various objects
    G = computeG ? resultsθ.G : nothing
    computeG  && ( G .= T( 0.0 ) )
    if computeH
        Hθθ = resultsθ.Hθθ
        Hδθ = resultsθ.Hδθ
        Hθθ .= T( 0.0 )
        Hδθ .= T( 0.0 )
    else 
        Hθθ = nothing; Hδθ = nothing 
    end

    # now do the actual computations, bearing in mind that the gradients and Hessians are added
    MacroObjectiveθ!( nothing, G, Hθθ, Hδθ, θ, macrodata )
    MicroObjectiveθ!( nothing, G, Hθθ, Hδθ, θ, microdata )
    ExponentiationCorrection!( G, Hθθ, Hδθ, θ, size( microdata.Z,3 ) + 1 )
    nothing
end




function ObjectiveFunctionθStandard!( results::Vector{Resultsδθ{T}}, F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T}, Nothing}, θzexpθν::Vector{T}, data::Vector{MarketData{T}} ) where {T<:Flt}
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
    dz = size( data[1].microdata.Z, 3 );  dθ = size( data[1].macrodata.A, 3 )
    computeH && !computeG && ( computeG = true; G = zeros(T, dθ ) )   # need G for exponentiation if H is to be computed
    θ = [ t ≤  dz ? θzexpθν[t] : exp(θzexpθν[t]) for t ∈ eachindex(θzexpθν) ]

    @sync for m ∈ eachindex(data)
        @spawn ObjectiveFunctionθStandardOneMarket!( results[m].resultsθ, results[m].resultsδ, computeF, computeG, computeH, θ, data[m].microdata, data[m].macrodata )
    end        

    # now compute the objective function, gradient and Hessian, if desired
    computeF && ( F = sum( results[m].resultsθ.F[1] for m ∈ eachindex(results) ) )
    computeG && ( G .= sum( results[m].resultsθ.G for m ∈ eachindex(results) ) )
    computeH && ( H .= sum( results[m].resultsθ.Hθθ - results[m].resultsθ.Hδθ' * inv( results[m].resultsδ.Hδδ ) * results[m].resultsθ.Hδθ for m ∈ eachindex(results) ) )
    F    
end



function 😠😠😠😠Standard( θstart::Vector{T}, data::Vector{GrumpsData{T}}  )   where {T<:Flt}
    marketdata = [ MarketData( data[m] ) for m ∈ eachindex(data) ]
    resultsδθ = [ Resultsδθ( marketdata[m] ) for m ∈ eachindex(data)  ]
    println( resultsδθ )
    Ω!( F::Union{T, Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, θzexpθν::Vector{T} ) =  ObjectiveFunctionθStandard!( resultsδθ, F, G, H, θzexpθν, marketdata ) 
    dz = size( marketdata[1].microdata.Z, 3 );  dθ = size( marketdata[1].macrodata.A, 3);  
    dδ = zeros( Int, length(data) )
    for m ∈ eachindex(marketdata)
        dδ[m] = size( marketdata[m].macrodata.A, 2) - 1
    end
    dδsum = sum( dδ )
    # dδ = [ size( data[m].macrodata.A, 2 ) -1 for m ∈ eachindex(data) ];  dδsum = sum( dδ )
    θzexpθνstart = [ t ≤ dz ? θstart[t] : log( θstart[t] ) for t ∈ eachindex(θstart) ]
    res = optimize( Optim.only_fgh!(Ω!), θzexpθνstart, NewtonTrustRegion(), Optim.Options(show_trace=true, extended_trace = true, x_tol=0.0, g_tol=1.0e-4, iterations=50 ) )
    @warn "Need to undo the exponentiation correction in asymptotic variance still"
    Ω!( T(0.0), zeros( T, dθ ), zeros( T, dθ, dθ ), res.minimizer   )
    Results( resultsδθ, res.minimizer, res.minimum, dz )
end

GrumpsStandard = 😠😠😠😠Standard



# *************  
# *           *
# * SC Grumps *
# *           *
# *************





function ObjectiveFunctionθSCOneMarket!( resultsθ::Resultsθ{T}, resultsδ::Resultsδ{T}, computeF::Bool, computeG::Bool, computeH::Bool, θ::Vector{T}, microdata::MicroData{T}, macrodata::MacroData{T} ) where {T<:Flt}

    # first calculate δ
    # these constructors might be slow; should check
    dz = size( microdata.Z, 3);  dθ = size( macrodata.A, 3 )
    macrodata.Aθ[:,:] = [ sum( macrodata.A[r,j,t] * θ[t] for t ∈ 1:dθ ) for r ∈ axes( macrodata.A, 1 ), j ∈ axes( macrodata.A, 2 ) ]    
    microdata.ZXθ[:,:,:] =  [ sum( microdata.Z[i,j,t] * θ[t] for t ∈ 1:dz ) + sum( microdata.X[r,j,t] * θ[dz+t] for t ∈ 1:dθ-dz ) for r ∈ axes( microdata.X, 1), i ∈ axes( microdata.Z, 1 ), j ∈ axes( microdata.X, 2 ) ]
    😠😠😠😠SCδ!( resultsδ, macrodata, zeros( T, size( macrodata.A, 2  ) - 1  ) )         # compute δ for given θ   
    resultsθ.F .= resultsδ.F

    # return if no derivatives are needed
    computeG || computeH || return 

    # now initialize the various objects
    G = computeG ? resultsθ.G : nothing
    computeG  && ( G .= T(0.0) )
    if computeH
        Hθθ = resultsθ.Hθθ
        Hδθ = resultsθ.Hδθ
        Hδδ = resultsθ.Hδδ
        Hθθ .= T(0.0)
        Hδθ .= T(0.0)
        Hδδ .= T(0.0)
        resultsδ.Hδθ .= T(0.0)
    else 
        Hθθ = nothing; Hδθ = nothing 
    end

    # now do the actual computations, bearing in mind that the gradients and Hessians are added
    if computeH 
        MacroObjectiveθ!( nothing, nothing, nothing, resultsδ.Hδθ, θ, macrodata )    # picks up cross partial of macro objective function
        ExponentiationCorrection!( nothing, nothing, resultsδ.Hδθ,  θ, microdata.dz + 1 )
        MicroObjectiveδ!( nothing, nothing, resultsθ.Hδδ, vcat( resultsδ.δ, T(0.0) ), microdata )
    end
    MicroObjectiveθ!( nothing, G, Hθθ, Hδθ, θ, microdata )
    ExponentiationCorrection!( G, Hθθ, Hδθ, θ,  microdata.dz + 1 )
    nothing
end




function ObjectiveFunctionθSC!( results::Vector{Resultsδθ{T}}, F::Union{T,Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T}, Nothing}, θzexpθν::Vector{T}, data::Vector{MarketData{T}} ) where {T<:Flt}
    computeF = F ≠ nothing;  computeG = G ≠ nothing;  computeH = H ≠ nothing
    dz = size( data[1].microdata.Z, 3 );  dθ = size( data[1].macrodata.A, 3 )
    computeH && !computeG && ( computeG = true; G = zeros(T, dθ ) )   # need G for exponentiation if H is to be computed
    θ = [ t ≤  dz ? θzexpθν[t] : exp(θzexpθν[t]) for t ∈ eachindex(θzexpθν) ]

    # @sync for m ∈ eachindex(data)
    #     @spawn ObjectiveFunctionθSCOneMarket!( results[m].resultsθ, results[m].resultsδ, computeF, computeG, computeH, θ, data[m].microdata, data[m].macrodata )
    # end        
    for m ∈ eachindex(data)
        ObjectiveFunctionθSCOneMarket!( results[m].resultsθ, results[m].resultsδ, computeF, computeG, computeH, θ, data[m].microdata, data[m].macrodata )
    end        

    # now compute the objective function, gradient and Hessian, if desired
    computeF && ( F = sum( results[m].resultsθ.F[1] for m ∈ eachindex(results) ) )
    computeG && ( G .= sum( results[m].resultsθ.G for m ∈ eachindex(results) ) )
    computeH || return F
    H .= T(0.0)
    for m ∈ eachindex(results)
        (resultsδ, resultsθ) = ( results[m].resultsδ, results[m].resultsθ )
        Ψθθ = resultsθ.Hθθ;  Ψδθ = resultsθ.Hδθ;  Ψδδ = resultsθ.Hδδ
        Λδθ = resultsδ.Hδθ;  Λδδ = resultsδ.Hδδ;  invΛδδ = inv( Λδδ )
        H[:,:] += Ψθθ - Ψδθ' * invΛδδ * Λδθ - Λδθ' * invΛδδ * Ψδθ + Λδθ' * invΛδδ * Ψδδ * invΛδδ * Λδθ
    end
    F    
end




function 😠😠😠😠SC( θstart::Vector{T}, data::Vector{GrumpsData{T}}  )   where {T<:Flt}
    marketdata = [ MarketData( data[m] ) for m ∈ eachindex(data) ]
    resultsδθ = [ Resultsδθ( marketdata[m], :SC ) for m ∈ eachindex(data)  ]
    Ω!( F::Union{T, Nothing}, G::Union{Vector{T},Nothing}, H::Union{Matrix{T},Nothing}, θzexpθν::Vector{T} ) =  ObjectiveFunctionθSC!( resultsδθ, F, G, H, θzexpθν, marketdata ) 
    dz = size( marketdata[1].microdata.Z, 3 );  dθ = size( marketdata[1].macrodata.A, 3);  
    dδ = zeros( Int, length(data) )
    for m ∈ eachindex(marketdata)
        dδ[m] = size( marketdata[m].macrodata.A, 2) - 1
    end
    dδsum = sum( dδ )
    θzexpθνstart = [ t ≤ dz ? θstart[t] : log( θstart[t] ) for t ∈ eachindex(θstart) ]
    res = optimize( Optim.only_fgh!(Ω!), θzexpθνstart, NewtonTrustRegion(), Optim.Options(show_trace=true, extended_trace = true, x_tol=0.0, g_tol=1.0e-4, iterations=50 ) )
    Ω!( T(0.0), zeros( T, dθ ), zeros( T, dθ, dθ ), res.minimizer   )
    @warn "need to work out correct asymptotic variance here"
    Results( resultsδθ, res.minimizer, res.minimum, dz )
end

GrumpsSC = 😠😠😠😠SC


