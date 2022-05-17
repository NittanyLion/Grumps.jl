



function microsampler( s :: GrumpsSamplers )
    return s.microsampler
end


function macrosampler( s :: GrumpsSamplers )
    return s.macrosampler
end

function show( io :: IO, s :: GrumpsSamplers )
    print( microsampler( s ), " and ", macrosampler( s ) ) 
 end
 
 