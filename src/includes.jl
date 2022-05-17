

include( "packages/packages.jl" )

import Base.show, Base.Threads.@threads, Base.Threads.nthreads, Base.Threads.threadid, Base.Threads.@spawn


# for fn ∈ [ "common", "mixedlogit", "vanilla" ]
#     include( "$fn/$(fn).jl" )
# end

const commondir = "common"
const docdir    = "doc"
const pkgdir    = "packages"

include( "$(commondir)/$(commondir).jl" )


function EstimatorFolders( )
    ests = String[]
    for fn ∈ readdir()
        if isdir( fn ) && fn[1] ∉ [ '.', '_' ] && fn ∉ [ commondir, docdir, pkgdir ]
            ests = vcat( ests, fn )
        end
    end
    @info "estimators = $ests" 
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


@info "$estdesc"




for e ∈ estfolds
    @info "loading $e"
    include( "$(e)/$(e).jl" )
end
