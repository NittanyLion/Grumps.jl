

for fn ∈ [ "error", "early", "types", "est", "utils", "io", "integration", "data", "sol", "space", "optim", "probs", "array", "imports", "tree", "inference", "compat" ]
    include( "$fn/$(fn).jl" )
end


# include( "error/error.jl" )
# include( "early/early.jl" )
# include( "types/types.jl" )
# include( "est/est.jl" )
# include( "utils/utils.jl" )
# include( "io/io.jl" )
# include( "integration/integration.jl" )
# include( "data/data.jl" )
# include( "sol/sol.jl" )
# include( "space/space.jl" )
# include( "optim/optim.jl" )
# include( "probs/probs.jl" )
# include( "array/array.jl" )
# include( "imports/imports.jl" )
# include( "tree/tree.jl" )
# include( "inference/inference.jl" )
# include( "compat/compat.jl" )

