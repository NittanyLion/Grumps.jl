

for fn ∈ [ "float", "array", "constraint" , "version", "variables", "options", "est", "user", "nodesweights", "source", "balance", "data", "fgh", "sol", "semaphore", "memblock", "space", "optim"]
    include( "$(fn).jl" )
end



