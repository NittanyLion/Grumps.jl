push!(LOAD_PATH, "../src")

using Documenter, Grumps



makedocs( sitename = "Grumps.jl",
    authors = "Joris Pinkse",
    pages = [
    "Home" => "index.md",
    "Quick Start" => "quickstart.md"
    ]
    )
