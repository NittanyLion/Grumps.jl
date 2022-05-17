Space( e :: GrumpsEstimator, d :: GrumpsData{T}, o :: OptimizationOptions ) where {T<:Flt} = GrumpsSpace( d, o )


function GiveMeSpace!( s :: GrumpsSpace{T}, m :: Int ) where {T<:Flt}
    if !memsave( s )
        s.marketspace[m].taken .= true
        return m
    end
    @ensure false "memsave not yet implemented" 
end

function ReleaseSpace!( s :: GrumpsSpace{T}, memslot :: Int ) where {T<:Flt}
    s.marketspace[memslot].taken .= false
    if !memsave( s )
        return nothing
    end
    @ensure false "memsave not yet implemented" 
end
