
@todo 2 "not sure if last call to pick up δ is needed"


"""
    grumps( 
        e       :: Estimator,
        d       :: Data{T},
        o       :: OptimizationOptions = OptimizationOptions(),
        θstart  :: StartingVector{T} = nothing,
        seo     :: StandardErrorOptions = StandardErrorOptions()
    )

Conducts the optimization.  You typically just want to set θstart to nothing, i.e. have a starting vector 
picked automatically.  
"""
function grumps( e :: Estimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}

    θstart      = StartingValues( θstart, e, d, o )
    fgh         = FGH( e, d )
    s           = Space( e, d, o )
    solution    = Solution( e, d, seo )
    
    δ           = [ zeros( T, dimm ) for dimm ∈ dimδm( d )  ]
    # CheckSanity( e, d, o, s )
    oldx = zeros( T, dimθ( d ) )
    repeatx = zeros( Int, 1 )

    @time result = Optim.optimize(
            Optim.only_fgh!(  ( F, G, H, θ ) ->  ObjectiveFunctionθ!( fgh, F, G, H, θ, δ, e, d, o, s ) ),
                θstart, 
                NewtonTrustRegion(), 
                Optim.Options(
                show_trace      = false,
                extended_trace  = o.θ.extended_trace,
                x_tol           = o.θ.x_tol,
                g_tol           = o.θ.g_tol,
                f_tol           = o.θ.f_tol,
                iterations      = o.θ.iterations,
                store_trace     = o.θ.store_trace,
                callback        = x->GrumpsθCallBack( x, e, d, o, oldx, repeatx, solution )
            )
    )

    θtr = Optim.minimizer( result )
    θ = getθ( θtr, d )
    Unbalance!( θ, d )

    ObjectiveFunctionθ!( fgh, zero(T), nothing, nothing, θtr , δ, e, d, o, s )         # pick up δ
    
    δvec = vcat( δ... )

    Computeβ!( solution, δvec, d )
    SetResult!( solution, θ, δvec, nothing )
    return solution
end


grumps( e :: Estimator, d :: Data{T} ) where {T<:Flt} = grumps( e, d, GrumpsOptimizationOptions(), nothing, StandardErrorOptions() )
grumps( e :: Estimator, d :: Data{T}, o :: OptimizationOptions ) where {T<:Flt} = grumps( e, d, o, nothing, StandardErrorOptions() )
