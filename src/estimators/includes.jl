




const estfolder = String( @__DIR__ )

function EstimatorFolders( )
    ests = String[]
    for fn ∈ readdir( estfolder )
        ffn = "$estfolder/$fn"
        if isdir( ffn ) && fn[1] ∉ [ '.', '_' ] && fn ∉ [ commondir, docdir, pkgdir ]
            @info "loading estimator $fn from $ffn"
            ests = vcat( ests, fn )
        end
    end
    return ests
end

const estfolds = EstimatorFolders()


struct EstimatorDescription
    symbol          :: Symbol
    name            :: String
    descriptions    :: Vector{String}
end


for e ∈ estfolds
    include( "$(e)/description.jl" )
end


const estdesc = [ Description( Symbol( e ), Val( Symbol( e ) ) ) for e ∈ estfolds ]






for e ∈ estfolds
    @info "loading $e"
    include( "$(e)/$(e).jl" )
end
