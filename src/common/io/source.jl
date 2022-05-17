

"""
    readfromfile( f :: SourceFileCSV )

Reads a CSV file and returns a DataFrame
"""
function readfromfile( f :: SourceFileCSV ) :: DataFrame
    df = try CSV.File( f.filename, delim = f.delimiter ) |> DataFrame
    catch
        throwargerr( "having trouble reading $(f.filename)")
    end
    return df
end


"""
    readfromfile( s :: GrumpsSources{T} )

Any entries in GrumpsSources that are of a SourceFile type get read as a DataFrame and an updated Sources variable is returned
"""
function readfromfile( s :: GrumpsSources{T} ) where {T} 
    fields = [ :consumers, :products, :marketsizes, :draws, :user ]
    values = Vec{T}(undef, length(fields) )
    for i ∈ eachindex( fields )
        f = getfield( s, fields[i] )
        values[i] = isa( f, SourceFileType ) ? readfromfile( f ) : f
    end
    return Sources( T, values... )
end
