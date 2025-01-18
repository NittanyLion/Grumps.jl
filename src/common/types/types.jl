

for fn ∈ [ "float", "array", "constraints" , "version", "variables", "options", "est", "user", "nodesweights", "source", "balance", "data", "fgh", "sol", "semaphore", "memblock", "space", "optim"]
    include( "$(fn).jl" )
end



