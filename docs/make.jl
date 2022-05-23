push!(LOAD_PATH, "../src")

using Documenter, Grumps

Grumps.@Imports()

import Grumps.Estimator

makedocs( sitename = "Grumps.jl",
    authors = "Joris Pinkse",
    pages = [
    "Home" => "index.md",
    "Quick Start" => "quickstart.md",
    "User Interface" => "objects.md",
    "Extending Grumps" => "extending.md"
    ]
    )
    
    
    deploydocs(;
    repo = "github.com/NittanyLion/Grumps.jl",
    devbranch = "main"
)

