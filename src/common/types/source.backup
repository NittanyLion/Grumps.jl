

"""
    Sources{T}

abstract mother type
"""
abstract type Sources{T} end
abstract type SourceFileType end


struct SourceFileCSV <: SourceFileType
    filename    :: String
    delimiter   :: String
end




const DefaultSourceTypes = Union{ DataFrame, Nothing, SourceFileType }

"""
    GrumpsSources{T}

Data type that contains information on filenames, dataframes, etc; see the Sources method for detailed information.
"""
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

Creates a GrumpsSources object with source type entries of type T where the entries are provided in the optional parameters.

Grumps (potentially) uses four data sources: a data source for consumer-level data, one for product-level data, one for market size information, and one for demographic draws.  See [Spreadsheet formats](@ref) for data layouts. Only the
product-level data are required, but are by themselves insufficient.  For instance, for BLP95 one needs information on products, market sizes, and demographics; for the Grumps CLER estimator one needs
all four types of data; for a multinomial logit both consumer and product information are needed.  Not all data are needed for all markets.  For instance, it is ok for some estimators for there to
be consumer-level data in some markets but not others.

The T argument is mostly there to allow for future expansion, so the description below applies to the case in which T = DefaultSourceTypes.
    
By default, the entries can be nothing, a string, a DataFrame, or a SourceFileType.  If an entry is nothing, it means that no such data is to be used.  If an entry is a string then it is converted to a SourceFileCSV entry with comma delimiter where the string name is the file name.  To use other source file types, create a SourceFileType first.  A DataFrame can be passed, also.  In all cases other than nothing, data will eventually be (converted to) a DataFrame and parsed from that.

The *consumers* variable specifies where consumer-level data can be found, the *products* variable is for the product-level data, *marketsizes* is for market sizes, and *draws* is for demographic draws; *user* has not been implemented yet.

Use the [`Variables()`](@ref) method to specify the way the data sources are formatted and the specification to estimate.
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
    Sources( T, consumers, products,  marketsizes, draws, user )

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


