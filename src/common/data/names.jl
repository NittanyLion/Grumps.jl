

"""
VariableNames( inter, racos, regrs, maprs, uintr, uracs )

Creates an object of type VariableNames which contains labels for each of the coefficients.  It 
takes the following arguments:

*inter* a matrix of symbols containing consumer and product variable descriptors
*racos* a vector of symbols indicating which variables receive random coefficients
*regrs* a vector of symbols describing second stage regressor variables
*maprs* a matrix of AbstractStrings describing market, product combinations
*uintr* a vector of AbstractStrings describing additional user interactions
*uracs* a vector of AbstractStrings describing additional user random coefficients
"""
function VariableNames(  
    interactions            :: Mat, 
    randomcoefficients      :: Vec,
    regressors              :: Vec,
    instruments             :: Vec,
    marketproductstrings    :: Mat{<:AbstractString}
)

    # first determine the names of the θ variables
    dθz = size( interactions, 1 ) 
    dθν = length( randomcoefficients ) 
    dθ =  dθz + dθν
    θnames = Vec{String}( undef, dθ )
    for r ∈ axes( interactions, 1 )
        θnames[ r ] = ( interactions[r,2] == :constant ) ? "$(interactions[r,1])" : "$(interactions[r,1]) * $(interactions[r,2])"
    end
    for r ∈ eachindex( randomcoefficients )
        θnames[ dθz + r ] = "rc on $(randomcoefficients[r])"
    end
    
    # now get the names of the β variables
    βnames = string.( regressors )

    # now get the names of the instruments
    bnames = string.( instruments )

    # now get the names of the δ variables
    δnames = [ "$(marketproductstrings[r,2]) in $(marketproductstrings[r,1] )" for r ∈ axes( marketproductstrings, 1 ) ]

    return VariableNames( θnames, βnames, bnames, δnames )
end

