






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



function StartingValues( θstartpassed :: Vec{T}, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions; automaticstartingvalues = false ) where {T<:Flt}
    dθ, dθz, dθν = dimsθ( d )

    θstart = automaticstartingvalues ? vcat( θstartpassed[1:dθz], [ θstartpassed[t] * d.balance[t].σ for t ∈ dθz + 1 : dθz] ) :
                 [ θstartpassed[t] * d.balance[t].σ for t ∈ eachindex( θstartpassed ) ] : 

    for t ∈ dθz+1:dθ
        @ensure θstart[t] > zero( T )  "random coefficient starting value must be positive"
        θstart[t] = log( θstart[t] )
    end
    return θstart
end



"""
    StartingValues( θstart :: Nothing, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions; deprecatedstartingvalues = false )

    Sets automatic starting values.
"""
function StartingValues( θstartpassed :: Nothing, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions; deprecatedstartingvalues = false ) where {T<:Flt}

    dθ, dθz, dθν = dimsθ( d )
    θstart =  deprecatedstartingvalues ? vcat(  zeros(T,dθz), fill( T( 0.5 ), dθν ) ) :   fill( T(0.5), dθ )  
    deprecatedstartingvalues ||  @advisory "automatic starting values have changed; to get the old ones use deprecatedstartingvalues = true"

    return StartingValues( θstart, e, d, o; automaticstartingvalues = true )
end



function StartingValues( θstartpassed :: Nothing, e :: GrumpsEstimator, con :: Constraint{T}, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions; deprecatedstartingvalues = false ) where {T<:Flt}
    return con.A' * StartingValues( θstartpassed, e, d, o; deprecatedstartingvalues = deprecatedstartingvalues ) 
end