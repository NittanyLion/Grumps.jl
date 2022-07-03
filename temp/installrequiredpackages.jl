using Pkg

for p ∈ [
    "DataFrames",
    "CSV",
    "Printf", 
    "Random123", 
    "FastGaussQuadrature", 
    "StatsBase", 
    "Optim", 
    "StatsFuns", 
    "StringDistances", 
    "TypeTree", 
    "Smartphores", 
    "PointerArithmetic" 
]
    Pkg.add( p )
end

Pkg.update()

