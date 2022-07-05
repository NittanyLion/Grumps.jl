const Divvy = Vec{ Vec{ Int } }

function divvyup( n :: Int, N :: Int )
    @ensure n > 0 && N ≥ 0  "arguments should be positive and nonnegative respectively"
    revdivv = fill( 0, N )
    divvy = [ Int[] for i ∈ 1:n ]
    j = 1
    for i ∈ 1:N
        revdivv[i] = j
        push!( divvy[j], i )
        j = ( j < n ) ? j + 1 : 1
    end      
    divvy, revdivv
end


function MemoryNeeded( d :: GrumpsMarketData{T} ) where {T<:Flt}
    return MicroSpaceNeeded( dimR( d.microdata ), dimS( d ), dimJ( d ), dimθ( d ) ) +
           MacroSpaceNeeded( dimR( d.macrodata ), dimJ( d ), dimθ( d ) )
end


function MemoryNeeded( d :: GrumpsData{T}, divvy :: Divvy ) where {T<:Flt}
    n = length( divvy )
    needed = fill( 0, n )
    for i ∈ 1 : n
        for m ∈ divvy[i] 
            needed[i] = max( needed[i], MemoryNeeded( d.marketdata[m] ) )
        end
    end
    return needed
end



abstract type MemBlockian{T<:Flt} end

struct MemNoBlock{T<:Flt} <: MemBlockian{T}
end




struct MemBlock{T<:Flt} <: MemBlockian{T}
    mem     :: Vec{ Vec{T} }
    divvy   :: Divvy
    revdiv  :: Vec{ Int }

    function MemBlock( d :: GrumpsData{T2}, o :: OptimizationOptions, ::Val{ true } ) where {T2<:Flt}
        M = dimM( d )
        n = o.gth.markets
        if n ≥ M   
            @info "memory save option does not make sense here; reverting to greedy option"
            return MemBlock( d, o, Val( false ) )
        end
        @ensure n > 0   "need at least one memory chunk"
        # compute indexes first; inefficient but only done once and cheap anyway
        divvy, revdivv = divvyup( n, M )
        # now find out how much memory is needed
        needed = MemoryNeeded( d, divvy )
        memm = [ fill( typemax( T2 ), needed[i]  ) for i ∈ eachindex( needed ) ]
        return new{T2}( memm, divvy, revdivv )
    end

end

function MemBlock( d :: GrumpsData{T}, o :: OptimizationOptions, ::Val{ false } ) where {T<:Flt}
    return MemNoBlock{T}()
end



function MemBlock( d :: GrumpsData{T}, o :: OptimizationOptions ) where {T<:Flt}
    return MemBlock( d, o, Val( memsave( o ) ) )
end

function chunks( memblock :: MemBlock )
    return length( memblock.divvy )
end