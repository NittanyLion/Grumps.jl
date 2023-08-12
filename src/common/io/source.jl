

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
    return Sources( valcons, valprod, valmksz, valdraw )
end
