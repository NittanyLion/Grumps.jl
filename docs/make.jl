push!(LOAD_PATH, "../src")

using Documenter, Grumps

Grumps.@Imports()

import Grumps.Estimator

makedocs( sitename = "Grumps.jl",
    authors = "Joris Pinkse",
    pages = [
    "Home" => "index.md",
    "Installation" => "installation.md",
    "Quick start" => "quickstart.md",
    "User interface" => "objects.md",
    "Spreadsheet format" => "spreadsheet.md",
    "Example program" => "example.md",
    "Directory structure" => "structure.md",
    "Algorithm flow" => "flow.md",
    "Extending Grumps" => "extending.md"
    ]
    )
    
    
    deploydocs(;
    repo = "github.com/NittanyLion/Grumps.jl",
    devbranch = "main"
)

