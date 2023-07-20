push!(LOAD_PATH, "../src")

using Documenter, Grumps

const MimeTex = MIME{Symbol("text/tex")}
const MimeCSV = MIME{Symbol("text/csv")}
const MimeTxt = MIME{Symbol("text/plain")}
const MimeTexCSV = Union{ MimeTex, MimeCSV }
const MimeText = Union{ MimeTex, MimeCSV, MimeTxt }


makedocs( sitename = "Grumps.jl",
    authors = "Joris Pinkse",
    pages = [
    "Home" => "index.md",
    "Installation" => "installation.md",
    "Estimators" => "estimators.md",
    "Quick start" => "quickstart.md",
    "User interface" => "objects.md",
    "Spreadsheet formats" => "spreadsheet.md",
    "Example program" => "example.md",
    "Charlie's tutorial" => "tutorial.md",
    "Speed, memory, accuracy" => "speedmemory.md",
    "Things to bear in mind" => "bearinmind.md",
    "Extending Grumps" => "extending.md",
    "Languages other than Julia" => "aliens.md",
    "Directory structure" => "structure.md",
    "Algorithm flow" => "flow.md",
    "Miscellanea" => "misc.md",
    "Acknowledgments" => "acknowledgments.md",
    "License" => "license.md",
    "Versions" => "versions.md"
    ]
    )
    
    
    deploydocs(;
    repo = "github.com/NittanyLion/Grumps.jl",
    devbranch = "main"
)

