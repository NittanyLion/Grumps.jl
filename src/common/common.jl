

for fn ∈ [ "error", "early", "types", "est", "utils", "io", "sampling", "data", "sol", "space", "threads", "optim", "probs", "array", "imports" ]
    include( "$fn/$(fn).jl" )
end

