

include( "packages/packages.jl" )

import Base.show, Base.Threads.@threads, Base.Threads.nthreads, Base.Threads.threadid, Base.Threads.@spawn



const commondir = "common"
const docdir    = "doc"
const pkgdir    = "packages"
const estdir    = "estimators"
const intdir = "integrators"

include( "$(commondir)/$(commondir).jl" )

const rootfolder = String( @__DIR__ )

for dr ∈ [ estdir, intdir ]
    include( "$(dr)/includes.jl" )
end

