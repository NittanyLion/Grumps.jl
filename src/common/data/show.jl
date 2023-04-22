
function show( io :: IO, d :: GrumpsMacroDataAnt{T}; adorned = true ) where {T<:Flt}
    prstyledln( adorned, "GrumpsMacroData"; color = :green, bold = true)
    for pr ∈ [ [ "market: ", d.name],
               [ "memory mode: ", "Ant" ],
               [ "float type: ", T ],
               [ "𝒳: ", string( size( d.𝒳, 1 ), " by ", size( d.𝒳 ,2 ) )  ],
               [ "𝒟: ", string( size( d.𝒟, 1 ), " by ", size( d.𝒟, 2 ) ) ],
               [ "s: ", string( "sum to ", safesum( d.s ) ) ],
               [ "market size (net of micro): ", d.N ],
               [ "weights: ", string( "sum to ", safesum(d.w) ) ] ]
        prpair( adorned,  pr[1], pr[2] )
    end
    return nothing 
end


function show( io :: IO, d :: GrumpsMacroDataHog{T}; adorned = true ) where {T<:Flt}
    prstyledln( adorned, "GrumpsMacroData"; color = :green, bold = true)
    for pr ∈ [ [ "market: ", d.name],
               [ "memory mode: ", "Ant" ],
               [ "float type: ", T ],
               [ "𝒜: ", string( size( d.𝒜, 1 ), " by ", size( d.𝒜 ,2 ), " by ", size( d.𝒜, 3 ) )  ],
               [ "s: ", string( "sum to ", safesum( d.s ) ) ],
               [ "market size (net of micro): ", d.N ],
               [ "weights: ", string( "sum to ", safesum(d.w) ) ] ]
        prpair( adorned,  pr[1], pr[2] )
    end
    return nothing 
end

function show( io :: IO, d :: GrumpsMacroNoData; adorned = true ) 
    prstyledln( adorned, "GrumpsMacroData"; color = :green, bold = true)
    for pr ∈ [ [ "market: ", d.name],
               [ "data: ", "none" ] ]
        prpair( adorned,  pr[1], pr[2] )
    end
    return nothing 
end



function show( io :: IO, d :: GrumpsMicroDataHog{T}; adorned = true ) where {T<:Flt}
    prstyledln( adorned, "GrumpsMicroData"; color = :green, bold = true)
    for pr ∈ [ [ "market: ", d.name],
               [ "memory mode: ", "Hog" ],
               [ "float type: ", T ],
               [ "Z: ", string( size( d.Z, 1 ), " by ", size( d.Z ,2 ), " by ", size( d.Z, 3 ) )  ],
               [ "X: ", string( size( d.X, 1 ), " by ", size( d.X ,2 ), " by ", size( d.X, 3 ) )  ],
               [ "y: ", string( "range ", "$(safeminimum( d.y )) to $(safemaximum( d.y ) )" ) ],
               [ "Y: ", string( "sum to ", safesum( d.Y ) ) ],
               [ "weights: ", string( "sum to ", safesum(d.w) ) ] ]

        prpair( adorned,  pr[1], pr[2] )
    end
    return nothing 
end


function show( io :: IO, d :: GrumpsMicroDataAnt{T}; adorned = true ) where {T<:Flt}
    prstyledln( adorned, "GrumpsMicroData"; color = :green, bold = true)
    for pr ∈ [ [ "market: ", d.name],
               [ "memory mode: ", "Ant" ],
               [ "float type: ", T ],
               [ "Z: ", string( size( d.Z, 1 ), " by ", size( d.Z ,2 ), " by ", size( d.Z, 3 ) )  ],
               [ "𝒳: ", string( size( d.𝒳, 1 ), " by ", size( d.𝒳 ,2 ) ) ],
               [ "𝒟: ", string( size( d.𝒟, 1 ), " by ", size( d.𝒟 ,2 ) ) ],
               [ "y: ", string( "range ", "$(safeminimum( d.y )) to $(safemaximum( d.y ) )" ) ],
               [ "Y: ", string( "sum to ", safesum( d.Y ) ) ],
               [ "weights: ", string( "sum to ", safesum(d.w) ) ] ]

        prpair( adorned,  pr[1], pr[2] )
    end
    return nothing 
end


function show( io :: IO, d :: GrumpsMicroNoData; adorned = true ) 
    prstyledln( adorned, "GrumpsMicroData"; color = :green, bold = true)
    for pr ∈ [ [ "market: ", d.name],
               [ "data: ", "none" ] ]
        prpair( adorned,  pr[1], pr[2] )
    end
    return nothing 
end



function show( io :: IO, vn :: VariableNames; adorned = true, printδ = false)
    prstyledln( adorned, "Variables used:"; color = :green, bold = true )
    for fn ∈ [ :θnames, :βnames, :δnames ]
        firstletter = string( fn )[1]
        prstyledln( adorned, "    $firstletter coefficients:"; color = :blue, bold = true )
        if firstletter == 'δ' && !printδ
            @printf( "%30s\n", "printing not requested") 
            continue
        end
        s = getfield( vn, fn )
        for t ∈ eachindex( s )
            @printf( "%30s\n", s[t] )
        end
    end
    return nothing
end


function show( io :: IO, d :: GrumpsData{T}; adorned = true ) where {T<:Flt}
    prstyledln( adorned, "GrumpsData{$T}"; color = :magenta, bold = true )
    for fn ∈ fieldnames( typeof( d ) )
        f = getfield( d, fn )
        prstyledln( adorned, "  $fn:"; color = 93, bold = true )
        if typeof( f ) <: Vector
            for i ∈ eachindex( f )
                println( "   ", f[i] )
            end
        else
            println( "   ", f )
        end
    end    
    return nothing
end

function show( io :: IO, d :: GrumpsPLMData{T}; adorned = true) where {T<:Flt}
    prstyledln( adorned, "GrumpsPLMData{$T}"; color = :magenta, bold = true )
    prstyledln( adorned, "  second stage regressors:"; color = 93, bold = true )
    for s ∈ d.names
        println( "    ", s )
    end
    return nothing
end




