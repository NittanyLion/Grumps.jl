

for fn ∈ [ "float", "array", "version", "variables", "options", "est", "user", "nodesweights", "source", "balance", "data", "fgh", "sol", "space", "optim" ]
    include( "$(fn).jl" )
end



