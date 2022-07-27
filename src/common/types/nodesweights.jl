


abstract type NodesWeights{T<:Flt} end


struct GrumpsNodesWeights{T} <: NodesWeights{T}
    nodes       :: Mat{T}
    weights     :: Vec{T}
end

struct MSMMicroNodesWeights{T} <: NodesWeights{T}
    nodes       :: A3{T}
    weights     :: Mat{T}
end


function GrumpsNodesWeights( nodes :: Mat{T}, weights :: Vec{T}  ) where {T<:Flt}
    return GrumpsNodesWeights{T}( nodes, weights )
end

function GrumpsNodesWeights( T = F64 )
    return GrumpsNodesWeights( zeros(T,0,0), zeros(T,0) )
end

function MSMMicroNodesWeights( nodes :: A3{T}, weights :: Vec{T}  ) where {T<:Flt}
    return MSMMicroNodesWeights{T}( nodes, weights )
end

function MSMMicroNodesWeights( T = F64 )
    return MSMMicroNodesWeights( zeros(T,0,0,0), zeros(T,0,0) )
end



abstract type GrumpsIntegrator{T<:Flt} end

abstract type MicroIntegrator{T<:Flt} <: GrumpsIntegrator{T} end

struct DefaultMicroIntegrator{T<:Flt} <: MicroIntegrator{T}   
    n   :: Int
end





"""
    DefaultMicroIntegrator( n :: Int, T :: Type )

Creates a basic quadrature Integrator using n nodes in each dimension.  Type T can be omitted, in which case it is Float64.
"""
function DefaultMicroIntegrator( n :: Int, T = F64 )
    @ensure n > 0  "n must be positive"
    DefaultMicroIntegrator{T}( n )
end

"""
    DefaultMicroIntegrator( T :: Type )

Creates a basic quadrature Integrator using 11 nodes in each dimension.  This number is likely too small, so use the other method to pick your number.  Type T can be omitted, in which case it is Float64.
"""
function DefaultMicroIntegrator( T = F64 )
    DefaultMicroIntegrator( 11, T )
end

struct MSMMicroIntegrator{T<:Flt} <: MicroIntegrator{T}
    n   :: Int
end


"""
    MSMMicroIntegrator( n :: Int, T = F64 )

Creates a Monte Carlo integrator type for *micro* integration with GMM with smart moments.  The optional type can be omitted.
"""
function MSMMicroIntegrator( n :: Int, T = F64 )
    @ensure n > 0  "n must be positive"
    MSMMicroIntegrator{T}( n )
end

"""
    MSMMicroIntegrator( T = F64 )

Creates a Monte Carlo integrator type for *micro* integration with GMM with smart moments with 10 MC draws (per consumer).
The type variable is optional and can be omitted.
"""
function MSMMicroIntegrator( T = F64 )
    MSMMicroIntegrator{T}( 10 )
end

abstract type MacroIntegrator{T<:Flt} <: GrumpsIntegrator{T} end

struct DefaultMacroIntegrator{T<:Flt} <: MacroIntegrator{T}   
    n   :: Int
end

"""
    DefaultMacroIntegrator( n :: Int, T :: Type )

Creates a basic Monte Carlo Integrator using n draws.  Type T can be omitted, in which case it is Float64.
"""
function DefaultMacroIntegrator( n :: Int, T::Type = F64 )
    DefaultMacroIntegrator{T}( n )
end

"""
    DefaultMacroIntegrator( T )

Creates a basic Monte Carlo Integrator using 10 000 draws.  This is less than recommended, so use the other method to set a number of your choosing.  Type T can be omitted, in which case it is Float64.
"""
function DefaultMacroIntegrator( T::Type = F64 )
    DefaultMacroIntegrator( 10_000, T )
end

abstract type GrumpsIntegrators{T<:Flt} end

struct BothIntegrators{T} <: GrumpsIntegrators{T} 
    microintegrator :: MicroIntegrator{T}
    macrointegrator :: MacroIntegrator{T}
end

microintegrator( i :: BothIntegrators ) = i.microintegrator
macrointegrator( i :: BothIntegrators ) = i.macrointegrator

"""
    BothIntegrators( microIntegrator :: MicroIntegrator{T}, macroIntegrator :: MacroIntegrator{T} )  

Creates the type BothIntegrators containing both the indicated microIntegrator and macroIntegrator.  

Either argument can be omitted.  If both arguments are omitted then one can pass the floating point
type T instead.  If no floating point type is passed then a Float64 is assumed.
"""
function BothIntegrators( microIntegrator :: MicroIntegrator{T}, macroIntegrator :: MacroIntegrator{T} ) where {T<:Flt}
    return BothIntegrators{T}( microIntegrator, macroIntegrator )
end

function BothIntegrators( microIntegrator :: MicroIntegrator{T} ) where {T<:Flt}
    return BothIntegrators( microIntegrator, DefaultMacroIntegrator( T ) )
end

function BothIntegrators( macroIntegrator :: MacroIntegrator{T} ) where {T<:Flt}
    return BothIntegrators( DefaultMicroIntegrator(T), macroIntegrator )
end

function BothIntegrators( T = F64 ) 
    return BothIntegrators( DefaultMicroIntegrator( T ), DefaultMacroIntegrator( T ) )
end

