



@todo 2 "not sure if last call to pick up δ is needed"


"""
    grumps!( 
        e       :: Estimator,
        d       :: Data{T},
        o       :: OptimizationOptions = OptimizationOptions(),
        θstart  :: StartingVector{T} = nothing,
        seo     :: StandardErrorOptions = StandardErrorOptions();
        printstructure = true
    )

Conducts the optimization.  You typically just want to set θstart to nothing, i.e. have a starting vector 
picked automatically.  
"""
function grumps!( epassed :: Estimator, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions; printstructure = true ) where {T<:Flt}

    e = CheckSanity( epassed, d, o, θstart, seo )
    BLAS.set_num_threads( blasthreads( o ) )
    
    printstructure && PrintStructure( e, d, o, θstart, seo )
  
    memblock    = MemBlock( d, o )
    GC.@preserve memblock begin
        θstart      = StartingValues( θstart, e, d, o )
        fgh         = FGH( e, d )
        s           = Space( e, d, o, memblock )
        solution    = Solution( e, d, seo )
        

        δ           = [ zeros( T, dimm ) for dimm ∈ dimδm( d )  ]
        oldx = zeros( T, dimθ( d ) )
        repeatx = zeros( Int, 1 )

        result = Optim.optimize(
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

        ObjectiveFunctionθ!( fgh, zero(T), nothing, nothing, θtr, δ, e, d, o, s )         # pick up δ
    end
    
    δvec = vcat( δ... )

    Computeβ!( solution, δvec, d )
    @info "computing asymptotic variance if requested"
    ComputeVξ!( solution, δvec, d )
    SetResult!( solution, θ, δvec, nothing )
    SetConvergence!( solution, result )
    Unbalance!( fgh, d )

    ses!( solution, e, d, fgh, seo )
    
    return solution
end


grumps!( e :: Estimator, d :: Data{T}; printstructure = true ) where {T<:Flt} = grumps!( e, d, GrumpsOptimizationOptions(), nothing, StandardErrorOptions(); printstructure = printstructure  )
grumps!( e :: Estimator, d :: Data{T}, θstart :: Vec{T}; printstructure = true ) where {T<:Flt} = grumps!( e, d, GrumpsOptimizationOptions(), θstart, StandardErrorOptions(); printstructure = printstructure )
grumps!( e :: Estimator, d :: Data{T}, o :: OptimizationOptions; printstructure = true ) where {T<:Flt} = grumps!( e, d, o, nothing, StandardErrorOptions(); printstructure = printstructure )


function grumps( x...; y... )
    @warn "grumps() is deprecated; use grumps!() instead"
    return grumps!( x...; y... )
end


