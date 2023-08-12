


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
    DefaultMicroIntegrator( n :: Int, T :: Type = Float64; options = nothing )

Creates a basic quadrature Integrator using n nodes in each dimension.  Type T can be omitted, in which case it is Float64. The options variable is ignored.
"""
function DefaultMicroIntegrator( n :: Int, T = F64; options = nothing )
    @ensure n > 0  "n must be positive"
    DefaultMicroIntegrator{T}( n )
end

"""
    DefaultMicroIntegrator( T :: Type; options = nothing )

Creates a basic quadrature Integrator using 11 nodes in each dimension.   Type T can be omitted, in which case it is Float64.  The options variable is ignored.
"""
function DefaultMicroIntegrator( T = F64; options = nothing )
    DefaultMicroIntegrator( 11, T )
end

struct MSMMicroIntegrator{T<:Flt} <: MicroIntegrator{T}
    n   :: Int
end


"""
    MSMMicroIntegrator( n :: Int, T = F64; options = nothing )

Creates a Monte Carlo integrator type for *micro* integration with GMM with smart moments.  The optional type can be omitted.
The options variable is ignored.
"""
function MSMMicroIntegrator( n :: Int, T = F64; options = nothing )
    @ensure n > 0  "n must be positive"
    MSMMicroIntegrator{T}( n )
end

"""
    MSMMicroIntegrator( T = F64; options = nothing )

Creates a Monte Carlo integrator type for *micro* integration with GMM with smart moments with 10 MC draws (per consumer).
The type variable is optional and can be omitted.  The options variable is ignored.
"""
function MSMMicroIntegrator( T = F64; options = nothing )
    MSMMicroIntegrator{T}( 10 )
end

abstract type MacroIntegrator{T<:Flt} <: GrumpsIntegrator{T} end

struct DefaultMacroIntegrator{T<:Flt} <: MacroIntegrator{T}   
    n               :: Int
    randomize       :: Bool
    replacement     :: Bool
    weights         :: Symbol
end

"""
    DefaultMacroIntegrator( n :: Int, T :: Type; options :: Union{Vec{Symbol}, Nothing} = nothing )

Creates a basic Monte Carlo Integrator using n draws.  Type T can be omitted, in which case it is Float64.
The optional *options* argument can be used to indicate two possible changes from the default, namely
*:randomize* can be used to require randomization and *:replacement* to indicate randomization with 
replacement. The default for both is false. Note that *options* is either nothing or a vector of symbols.  
A further use of *options* is to specify a column heading containing weight; this symbol should correspond
to the desired column heading in the draws spreadsheet. 
"""
function DefaultMacroIntegrator( n :: Int, T::Type = F64; options :: Union{Vec{Symbol}, Nothing} = nothing )
    replacement = randomize = false
    weights = :uniform
    if options ≠ nothing
        for o ∈ options
            o == :randomize  && ( randomize = true )
            o == :replacement && ( randomize = replacement = true )
            if o ∉ [ :randomize, :replacement ]
                if weights == :uniform
                    weights = o
                else
                    @warn "unknown extra option $o ignored"
                end
            end
        end
    end
    if randomize == false 
        @info "no randomization chosen for macro integrator: just selecting from the start of the draws data if provided"
    else
        @info "drawing $( replacement ? "with" : "without" ) replacement from the draws data if provided"
    end 
    DefaultMacroIntegrator{T}( n, randomize, replacement, weights )
end

"""
    DefaultMacroIntegrator( T )

Creates a basic Monte Carlo Integrator using 10 000 draws.  This is less than recommended, so use the other method to set a number of your choosing.  Type T can be omitted, in which case it is Float64. The optional *options* argument can be used to indicate two possible changes from the default, namely
*:randomize* can be used to require randomization and *:replacement* to indicate randomization with 
replacement.  Note that *options* is either nothing or a vector of symbols.  The defaults for both is false.
A further use of *options* is to specify a column heading containing weight; this symbol should correspond
to the desired column heading in the draws spreadsheet. 
"""
function DefaultMacroIntegrator( T::Type = F64; options :: Union{Vec{Symbol}, Nothing} = nothing )
    DefaultMacroIntegrator( 10_000, T; options = options )
end

# abstract type GrumpsIntegrators{T<:Flt} end
abstract type GrumpsIntegrators{Mic,Mac} end

# struct BothIntegrators{T} <: GrumpsIntegrators{T} 
#     microintegrator :: MicroIntegrator{T}
#     macrointegrator :: MacroIntegrator{T}
# end


struct BothIntegrators{ Mic, Mac } <: GrumpsIntegrators{ Mic, Mac} 
    microintegrator :: Mic
    macrointegrator :: Mac

    function BothIntegrators( mic :: MicroIntegrator{T}, mac :: MacroIntegrator{T} ) where {T<:Flt}
        return new{ typeof(mic), typeof(mac) }( mic, mac )
    end
end

microintegrator( i :: BothIntegrators ) = i.microintegrator
macrointegrator( i :: BothIntegrators ) = i.macrointegrator

"""
    BothIntegrators( microIntegrator :: MicroIntegrator{T}, macroIntegrator :: MacroIntegrator{T} )  

Creates the type BothIntegrators containing both the indicated microIntegrator and macroIntegrator.  

Either argument can be omitted.  If both arguments are omitted then one can pass the floating point
type T instead.  If no floating point type is passed then a Float64 is assumed.
"""
# function BothIntegrators( microIntegrator :: MicroIntegrator{T}, macroIntegrator :: MacroIntegrator{T} ) where {T<:Flt}
#     return BothIntegrators{typeof{microIntegrator},typeof(macroIntegrator)}( microIntegrator, macroIntegrator )
# end

function BothIntegrators( microIntegrator :: MicroIntegrator{T} ) where {T<:Flt}
    return BothIntegrators( microIntegrator, DefaultMacroIntegrator( T ) )
end

function BothIntegrators( macroIntegrator :: MacroIntegrator{T} ) where {T<:Flt}
    return BothIntegrators( DefaultMicroIntegrator(T), macroIntegrator )
end

function BothIntegrators( T = F64 ) 
    return BothIntegrators( DefaultMicroIntegrator( T ), DefaultMacroIntegrator( T ) )
end



