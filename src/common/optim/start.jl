




"""
    StartingValues( θstart :: Union{Nothing, Vec{T}}, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions )

    Sets or rescales the starting values and then corrects them takes the logarithm of the random coefficients.
"""
function StartingValues( θstart :: Union{Nothing, Vec{T}}, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions ) where {T<:Flt}
    dθ, dθz, dθν = dimsθ( d )
    if θstart == nothing 
        θstart = vcat( zeros(T, dθz), fill( T(0.5), dθν ) )
    else
        for t ∈ 1:dθ
            θstart[t] *= d.balance[t].σ
        end
    end
    for t ∈ dθz+1:dθ
        @ensure θstart[t] > zero( T )  "random coefficient starting value must be positive"
        θstart[t] = log( θstart[t] )
    end
    println( "starting vector = $θstart" )
    return θstart
end

