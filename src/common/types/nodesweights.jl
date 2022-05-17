


abstract type NodesWeights{T<:Flt} end


struct GrumpsNodesWeights{T} <: NodesWeights{T}
    nodes       :: Mat{T}
    weights     :: Vec{T}
end

function GrumpsNodesWeights( nodes :: Mat{T}, weights :: Vec{T}  ) where {T<:Flt}
    return GrumpsNodesWeights{T}( nodes, weights )
end

function GrumpsNodesWeights( T = F64 )
    return GrumpsNodesWeights( zeros(T,0,0), zeros(T,0) )
end

abstract type GrumpsSampler{T<:Flt} end

abstract type MicroSampler{T<:Flt} <: GrumpsSampler{T} end

struct DefaultMicroSampler{T<:Flt} <: MicroSampler{T}   
    n   :: Int
end

function DefaultMicroSampler( n :: Int, T = F64 )
    DefaultMicroSampler{T}( n )
end

function DefaultMicroSampler( T = F64 )
    DefaultMicroSampler( 11, T )
end

abstract type MacroSampler{T<:Flt} <: GrumpsSampler{T} end

struct DefaultMacroSampler{T<:Flt} <: MacroSampler{T}   
    n   :: Int
end

function DefaultMacroSampler( n :: Int, T::Type = F64 )
    DefaultMacroSampler{T}( n )
end

function DefaultMacroSampler( T::Type = F64 )
    DefaultMacroSampler( 10_000, T )
end

abstract type GrumpsSamplers{T<:Flt} end

struct BothSamplers{T} <: GrumpsSamplers{T} 
    microsampler :: MicroSampler{T}
    macrosampler :: MacroSampler{T}
end

"""
    BothSamplers( microsampler :: MicroSampler{T}, macrosampler :: MacroSampler{T} ) where {T<:Flt}

Creates the type BothSamplers containing both the indicated microsampler and macrosampler.  

Either argument can be omitted.  If both arguments are omitted then one can pass the floating point
type instead.  If no floating point type is passed then a Float64 is assumed.
"""
function BothSamplers( microsampler :: MicroSampler{T}, macrosampler :: MacroSampler{T} ) where {T<:Flt}
    return BothSamplers{T}( microsampler, macrosampler )
end

function BothSamplers( microsampler :: MicroSampler{T} ) where {T<:Flt}
    return BothSamplers( microsampler, DefaultMacroSampler( T ) )
end

function BothSamplers( macrosampler :: MacroSampler{T} ) where {T<:Flt}
    return BothSamplers( Defaultmicrosampler{T}, macrosampler )
end

function BothSamplers( T = F64 ) 
    return BothSamplers( DefaultMicroSampler( T ), DefaultMacroSampler( T ) )
end

