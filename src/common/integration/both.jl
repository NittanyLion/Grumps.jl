



function microintegrator( s :: GrumpsIntegrators )
    return s.microintegrator
end


function macrointegrator( s :: GrumpsIntegrators )
    return s.macrointegrator
end

function show( io :: IO, s :: GrumpsIntegrators; adorned = true )
    prstyled( adorned, "Integrators used:\n"; color=:green, bold = true)
    print( "    "); print( microintegrator( s ) )
    print( "    "); println( macrointegrator( s ) ) 
 end
 
 