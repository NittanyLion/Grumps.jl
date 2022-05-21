

function grumps( e :: Estimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions ) where {T<:Flt}

    θstart      = StartingValues( θstart, e, d, o )
    fgh         = FGH( e, d )
    s           = Space( e, d, o )
    solution    = Solution( e, d, seo )
    
    # CheckSanity( e, d, o, s )

    @time result = Optim.optimize(
            Optim.only_fgh!(  ( F, G, H, θ ) ->  ObjectiveFunctionθ!( fgh, F, G, H, θ, e, d, o, s ) ),
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
                callback        = x->GrumpsθCallBack( x, e, d, o, zeros( T, dimθ( d ) ), [0], solution )
            )
    )

    θ = getθ( Optim.minimizer( result ), d )
    Unbalance!( θ, d )
    println( θ )

    SetResult!( solution, e, d, o, seo, result, fgh )
    return solution
end


grumps( e :: Estimator, d :: Data{T} ) where {T<:Flt} = grumps( e, d, GrumpsOptimizationOptions(), nothing, StandardErrorOptions() )
grumps( e :: Estimator, d :: Data{T}, o :: OptimizationOptions ) where {T<:Flt} = grumps( e, d, o, nothing, StandardErrorOptions() )
