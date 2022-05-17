using Grumps
using Documenter

DocMeta.setdocmeta!(Grumps, :DocTestSetup, :(using Grumps); recursive=true)

makedocs(;
    modules=[Grumps],
    authors="Joris Pinkse <pinkse@gmail.com> and contributors",
    repo="https://github.com/NittanyLion/Grumps.jl/blob/{commit}{path}#{line}",
    sitename="Grumps.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://NittanyLion.github.io/Grumps.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/NittanyLion/Grumps.jl",
    devbranch="main",
)
