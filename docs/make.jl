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
    "Spreadsheet formats" => "spreadsheet.md",
    "Example program" => "example.md",
    "Things to bear in mind" => "bearinmind.md",
    "Directory structure" => "structure.md",
    "Algorithm flow" => "flow.md",
    "Extending Grumps" => "extending.md",
    "Languages other than Julia" => "aliens.md"
    ]
    )
    
    
    deploydocs(;
    repo = "github.com/NittanyLion/Grumps.jl",
    devbranch = "main"
)

