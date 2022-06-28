



function microintegrator( s :: GrumpsIntegrators )
    return s.microintegrator
end


function macrointegrator( s :: GrumpsIntegrators )
    return s.macrointegrator
end

function show( io :: IO, s :: GrumpsIntegrators )
    print( microintegrator( s ), " and ", macrointegrator( s ) ) 
 end
 
 