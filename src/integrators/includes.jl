const intfolder = String( @__DIR__ )

function IntegratorFolders( )
    ints = String[]
    for fn ∈ readdir( intfolder )
        ffn = "$intfolder/$fn"
        if isdir( ffn ) && fn[1] ∉ [ '.', '_' ] && fn ∉ [ commondir, docdir, pkgdir ]
            ints = vcat( ints, fn )
        end
    end
    return ints
end

const intfolds = IntegratorFolders()

for i ∈ intfolds
    @info "loading $i"
    include( "$(i)/$(i).jl" )
end


