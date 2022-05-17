

function grumpsδ!( 
    fgh     :: GrumpsSingleFGH{T}, 
    θ       :: Vec{T},
    δ       :: Vec{T}, 
    e       :: GrumpsMLE, 
    d       :: GrumpsMarketData{T}, 
    o       :: OptimizationOptions, 
    s       :: GrumpsMarketSpace{T}, 
    m       :: Int 
    ) where {T<:Flt}

    result = Optim.optimize(
        Optim.only_fgh!( (F,G,H,δc)-> InsideObjective1!( F, G, H, nothing, θ, δc, e, d, o, s ) ), 
            𝓏𝓈( T, length( δ ) ), 
            NewtonTrustRegion(), 
            Optim.Options(
            show_trace      = false,
            extended_trace  = o.δ.extended_trace,
            x_tol           = o.δ.x_tol,
            g_tol           = o.δ.g_tol,
            f_tol           = o.δ.f_tol,
            iterations      = o.δ.iterations,
            store_trace     = o.δ.store_trace,
            callback        = x->GrumpsδCallBack( x, e, d, o, zeros( T, length( δ ) ), [0] )
        ) )

    copyto!( δ, result.minimizer )
    copyto!( s.microspace.lastδ, δ )
    fgh.F .= InsideObjective1!( zero(T), fgh.Gδ, fgh.Hδδ, fgh.Hδθ, θ, δ, e, d, o, s )

    return nothing    
end