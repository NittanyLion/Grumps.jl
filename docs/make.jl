push!(LOAD_PATH, "../src")

using Documenter, Grumps

Grumps.@Imports()


makedocs( sitename = "Grumps.jl",
    authors = "Joris Pinkse",
    pages = [
    "Home" => "index.md",
    "Quick Start" => "quickstart.md",
    "Methods and types" => "objects.md"
    ]
    )
    
    
    deploydocs(;
    repo = "github.com/NittanyLion/Grumps.jl",
    devbranch = "main"
)

