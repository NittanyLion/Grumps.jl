

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


GrabField( anyth ) = anyth
GrabField( f :: SourceFileType ) :: DataFrame = readfromfile( f )

"""
    readfromfile( s :: GrumpsSources )

Any entries in GrumpsSources that are of a SourceFile type get read as a DataFrame and an updated Sources variable is returned
"""
function readfromfile( s :: GrumpsSources )
    valcons = GrabField( s.consumers )
    valprod = GrabField( s.products )
    valmksz = GrabField( s.marketsizes )
    valdraw = GrabField( s.draws )
    println( typeof( valprod ) )
    return Sources( valcons, valprod, valmksz, valdraw )
end
# function readfromfile( s :: GrumpsSources ) 
#     fields = [ :consumers, :products, :marketsizes, :draws ]
#     values = Vec{T}(undef, length(fields) )
#     for i ∈ eachindex( fields )
#         f = getfield( s, fields[i] )
#         values[i] = isa( f, SourceFileType ) ? readfromfile( f ) : f
#     end
#     return Sources( values... )
# end
