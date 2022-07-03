

include( "packages/packages.jl" )

import Base.show, Base.Threads.@threads, Base.Threads.nthreads, Base.Threads.threadid, Base.Threads.@spawn



const commondir  = "common"
const docdir     = "doc"
const pkgdir     = "packages"
const estdir     = "estimators"
const intdir     = "integrators"
const rootfolder = String( @__DIR__ )

# @info "$rootfolder"
    


include( "$(commondir)/$(commondir).jl" )


for dr ∈ [ estdir, intdir ]
    include( "$(dr)/includes.jl" )
end
