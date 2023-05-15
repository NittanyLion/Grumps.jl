

const minimumversion = v"1.8.0-beta3"
@assert VERSION ≥ minimumversion  "need at least Julia $minimumversion"

using DataFrames, CSV, Printf, Random123, Random, FastGaussQuadrature, StatsBase, Optim, StatsFuns, LinearAlgebra, StringDistances, TypeTree, Smartphores, PointerArithmetic, SparseArrays
