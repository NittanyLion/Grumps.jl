


abstract type Sources{T} end
abstract type SourceFileType end


struct SourceFileCSV <: SourceFileType
    filename    :: String
    delimiter   :: String
end




const DefaultSourceTypes = Union{ DataFrame, Nothing, SourceFileType }


struct GrumpsSources{T} <: Sources{T} 
    consumers   :: T
    products    :: T
    marketsizes :: T
    draws       :: T
    user        :: T
end

"""
    Sources( 
        T           = DefaultSourceTypes; 
        consumers   :: Any = nothing, 
        products    :: Any = nothing, 
        marketsizes :: Any = nothing, 
        draws       :: Any = nothing,
        user        :: Any = nothing
    )

Creates a GrumpsSources object with source type entries of type T where
the entries are provided in the optional parameters.

By default, the entries can be nothing, a string, a DataFrame, or a SourceFileType.  If a string is entered then it is converted to a SourceFileCSV
entry with comma delimiter.
"""
function Sources( 
    T2          = DefaultSourceTypes; 
    consumers   :: Any = nothing, 
    products    :: Any = nothing, 
    marketsizes :: Any = nothing, 
    draws       :: Any = nothing,
    user        :: Any = nothing
 )

    a = Vector{Any}( [ consumers, products, marketsizes, draws, user ] )
    for i ∈ eachindex( a )
        if isa( a[i], String )                         # assume a comma delimited CSV file if only a string is specified
            a[i] = SourceFileCSV( a[i], "," )
        end
        @ensure typeof(a[i])<:T2  "$(a[i]) is not of type $T2" 
    end
    
    return GrumpsSources{T2}( a... ) 
    # GrumpsSources{T2}( consumers, products, marketsizes, draws, user ) 
end

"""
    function Sources( T, consumers, products,  marketsizes, draws, user )

Calls the method Sources with optional parameters.  Use the optional parameters version to avoid ambiguity and to avoid having to enter all arguments.  In other words: *don't use this method.*
"""
function Sources( T, consumers, products,  marketsizes, draws,  user )
    return Sources( T; consumers = consumers, products = products, marketsizes = marketsizes, draws = draws,  user = user )
end

function show( io :: IO, s :: SourceFileCSV ) 
    print( "$(s.filename)  text file delimited by a " )
    printstyled( s.delimiter; bold = true )
    return nothing
end


function show( io :: IO, s :: Sources ) 
    for f ∈ fieldnames( typeof( s ) )
        val = getfield( s, f )
        valp = ""
        if typeof( val ) <: DataFrame
            valp = "DataFrame"
        end
        if val == nothing
            valp = "unspecified"
        end
        # if typeof( val ) <: Real
        #     valp = "$val"
        # end
        printstyled( @sprintf( "%30s: ",f ); bold = true );  println( valp )
    end
    return nothing
end


