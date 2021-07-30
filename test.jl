using Optim, BenchmarkTools



f( x::Vector{Float64}, y::Vector{Float64} ) = sum( (x[i] - y[i])^2 for i ∈ 1:length(x) )
df( x::Vector{Float64}, y::Vector{Float64} ) = 2 * ( x - y )
ddf( x::Vector{Float64}, y::Vector{Float64} ) = [ (i==j) ? 2.0 : 0.0 for i ∈ 1:length(x), j ∈ 1:length(x) ]


function oops(y::Vector{Float64})
    function Ω!( F, G, H, x::Vector{Float64} ) 
        F == nothing || ( F = f(x,y) )
        G == nothing || ( G .= df(x,y) )
        H == nothing || ( H .= ddf(x,y) )
        F
    end
    result = Optim.optimize( Optim.only_fgh!(Ω!), zeros(length(y)), NewtonTrustRegion() )
    println( result )
    println( result.minimizer - y )
end


oops( randn(20) )