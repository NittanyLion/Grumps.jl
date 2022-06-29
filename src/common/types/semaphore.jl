
import Base.release
import Base.acquire
import Base.Semaphore


abstract type Semaphorian end

struct GrumpsNoSemaphores <: Semaphorian
end

struct GrumpsSemaphores <: Semaphorian
    semas :: Vec{ Semaphore }

    function GrumpsSemaphores( n :: Int )
        @ensure n ≥ 0  "n cannot be negative"
        return new( [Semaphore( 1 ) for i ∈ 1:n] )
    end
end


function acquire( s :: GrumpsSemaphores, t :: Int ) 
    @ensure 1 ≤ t ≤ length( s.semas )  "out of bounds"
    return acquire( s.semas[t] )
end

function release( s :: GrumpsSemaphores, t :: Int )
    @ensure 1 ≤ t ≤ length( s.semas ) "out of bounds"
    return release( s.semas[t] )
end


function acquire( s :: GrumpsNoSemaphores, t :: Int )
end

function release( s :: GrumpsNoSemaphores, t :: Int )
end
