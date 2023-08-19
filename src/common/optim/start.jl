






"""
    StartingValues( θstart :: Vec{T}, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions )

    Rescales the starting values and then corrects them; takes the logarithm of the random coefficients.
"""
function StartingValues( θstartpassed :: Vec{T}, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions ) where {T<:Flt}
    dθ, dθz, dθν = dimsθ( d )

    θstart = [ θstartpassed[t] * d.balance[t].σ for t ∈ eachindex( θstartpassed ) ]

    for t ∈ dθz+1:dθ
        @ensure θstart[t] > zero( T )  "random coefficient starting value must be positive"
        θstart[t] = log( θstart[t] )
    end
    return θstart
end



"""
    StartingValues( θstart :: Nothing, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions )

    Sets automatic starting values.
"""
function StartingValues( θstartpassed :: Nothing, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions ) where {T<:Flt}

    dθ, dθz, dθν = dimsθ( d )
    θstart = vcat( zeros(T, dθz), fill( T( 0.5 ), dθν ) )
    # θstart = vcat( fill( T( 0.5 ), dθ ) )
    return StartingValues( θstart, e, d, o )
end


