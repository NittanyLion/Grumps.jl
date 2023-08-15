

const minimumversion = v"1.8.0"
const desirableversion = v"1.9.2"
@assert VERSION ≥ minimumversion  "need at least Julia $minimumversion"
if VERSION < desirableversion
    @warn "Grumps works with Julia $minimumversion and higher, but $desirableversion or higher is preferred"
end

using DataFrames, CSV, Printf, Random123, Random, FastGaussQuadrature, StatsBase, Optim, StatsFuns, LinearAlgebra, StringDistances, TypeTree, Smartphores, SparseArrays, Dates, Ansillary, LoopVectorization, Tullio, OhMyREPL
