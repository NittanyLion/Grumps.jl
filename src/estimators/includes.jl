




const estfolder = String( @__DIR__ )

function EstimatorFolders( )
    ests = String[]
    for fn ∈ readdir( estfolder )
        ffn = "$estfolder/$fn"
        if isdir( ffn ) && fn[1] ∉ [ '.', '_' ] && fn ∉ [ commondir, docdir, pkgdir ]
            ests = vcat( ests, fn )
        end
    end
    return ests
end

const estfolds = EstimatorFolders()





for e ∈ estfolds
    include( "$(e)/description.jl" )
end


const estdesc = [ Description( Symbol( e ), Val( Symbol( e ) ) ) for e ∈ estfolds ]






for e ∈ estfolds
    @info "loading $e"
    include( "$(e)/$(e).jl" )
end


