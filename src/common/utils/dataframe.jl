
"""
    MustBeInDF( needle, haystack, description )

Checks if colum named needle (a Symbol) is one of the column headings in the haystack AbstractDataFrame
described by description.  If not, then it will print an error message.
"""
function MustBeInDF( needle :: Symbol, haystack :: AbstractDataFrame, description :: AbstractString )
    @ensure string( needle ) ∈ names( haystack )   "cannot find $needle in $description dataframe"
    return nothing
end 

"""
    MustBeInDF( needles :: Vector{Symbol}, haystack, description )

Calls the other method MustBeInDF for each element of needles.
"""
function MustBeInDF( needle :: Vec{Symbol},  haystack :: AbstractDataFrame, description :: AbstractString )
    for n ∈ needle
        MustBeInDF( n, haystack, description )
    end
    return nothing
end


"""
    AddConstant!( df :: DataFrame )

Adds a column called "constant" filled with 1.0's to df if it doesn't already have one.
"""
function AddConstant!( df :: DataFrame )
    if "constant" ∉ names( df ) 
        df[!,:constant] .= 1.0
    end
    return nothing
end

"""
    ExtractMatrixFromDataFrame( T :: Type, dfp :: AbstractDataFrame, cols :: Vector{Symbol} )

Extracts the columns in cols from the DataFrame stored in dfp and returns a Matrix with elements of type T
"""
function ExtractMatrixFromDataFrame( T :: Type{ 𝒯 }, dfp :: AbstractDataFrame, cols :: Vec{Symbol} ) where 𝒯
    MustBeInDF( cols, dfp, "" )
    return Mat{T}( dfp[ :, cols ] )
end

"""
    ExtractVectorFromDataFrame( T :: Type, dfp :: AbstractDataFrame, col :: Symbol )

Extracts the column in col from the DataFrame stored in dfp and returns a Vector with elements of type T
"""
function ExtractVectorFromDataFrame( T :: Type{ 𝒯 }, dfp :: AbstractDataFrame, col :: Symbol ) where 𝒯
    MustBeInDF( col,  dfp, "" )
    return Vec{T}( dfp[ :, col ] )
end

function ExtractVectorFromDataFrame( dfp :: AbstractDataFrame, col :: Symbol )
    MustBeInDF( col,  dfp, "" )
    return Vec( dfp[ :, col ] )
end

function ExtractDummiesFromDataFrame( T :: Type{𝒯}, dfp :: AbstractDataFrame, cols :: Vec{Symbol} ) where 𝒯
    if length( cols ) == 0
        return zeros( T, nrow(dfp), 0 ), Vec{String}( undef, 0 )
    end

    MustBeInDF( cols, dfp, "" )
    vals = [ sort( unique( dfp[:,cols[t]] ) )[1:end-1] for t ∈ eachindex( cols ) ]
    (start, finish) = StartFinish( vals )
    ndummies = finish[end]
    𝒟 = zeros( T, nrow( dfp ), ndummies )
    for j ∈ eachindex( vals )
        for t ∈ eachindex( vals[j] )
            𝒟[ findall( x->x == vals[j][t], dfp[ :, cols[j] ] ), start[j] + t - 1 ] .= one( T )
        end
    end
    
    varnames = Vec{String}( undef, ndummies )
    for j ∈ eachindex( vals )
        for t ∈ eachindex( vals[j] )
            varnames[ start[j]+t-1 ] = "dum_$(cols[j])_$(vals[j][t])"
        end
    end
    𝒟, varnames 
end


function ExtractDummiesFromDataFrameNoDrop( T :: Type{ 𝒯 }, dfp :: AbstractDataFrame, cols :: Vec{Symbol} ) where 𝒯
    E, = ExtractDummiesFromDataFrame( T, dfp, cols )
    X = [ T( 1 - sum( E[i,1:end] ) ) for i ∈ axes( E, 1 ) ]
    return hcat( E, X )
end

