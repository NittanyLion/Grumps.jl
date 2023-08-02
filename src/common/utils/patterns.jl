function printpatternlevel( s )
    clr = [ :green, :red, :cyan ]

    for j ∈ eachindex( s )
        @assert( s[j] ∈ ['0','1'] )
        printstyled( s[j] == '1' ? "■ " : "□ " ; color = clr[j]  )
    end
end


function printpatterninside( e )
    pat = iopattern( e )
    @ensure length( pat ) == 6 "invalid pattern for $e"
    printpatternlevel( pat[1:3] )
end


function printpatternoutside( e )
    pat = iopattern( e )
    @ensure length( pat ) == 6 "invalid pattern for $e"
    printpatternlevel( pat[4:6] )
end



