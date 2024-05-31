



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


"""
    grumps!( 
        e       :: Estimator,
        con     :: Constraint{T},
        d       :: Data{T},
        o       :: OptimizationOptions = OptimizationOptions(),
        θstart  :: StartingVector{T} = nothing,
        seo     :: StandardErrorOptions = StandardErrorOptions();
        printstructure = true
    )

Conducts the optimization.  You typically just want to set θstart to nothing, i.e. have a starting vector 
picked automatically.  
"""
function grumps!( epassed :: Estimator, con :: Constraint{T}, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions; printstructure = true ) where {T<:Flt}

    e = CheckSanity( epassed, con, d, o, θstart, seo )
    BLAS.set_num_threads( blasthreads( o ) )
    
    printstructure && PrintStructure( e, d, o, con, θstart, seo )
 
    memblock    = MemBlock( d, o )
    GC.@preserve memblock begin
        α           = StartingValues( θstart, e, con, d, o )
        fgh         = FGH( e, d )
        s           = Space( e, d, o, memblock )
        solution    = Solution( e, d, seo )
        dθ          = dimθ( d )
        dα          = dθ - dim( con )
        PrepareConstraint!( con, d )


        δ           = [ zeros( T, dimm ) for dimm ∈ dimδm( d )  ]
        oldx = zeros( T, dθ )
        repeatx = zeros( Int, 1 )

        result = Optim.optimize(
                Optim.only_fgh!(  ( F, G, H, α ) ->  ObjectiveFunctionα!( fgh, con, F, G, H, α, δ, e, d, o, s ) ),
                    θconstart, 
                    NewtonTrustRegion(), 
                    Optim.Options(
                    show_trace      = false,
                    extended_trace  = o.θ.extended_trace,
                    x_tol           = o.θ.x_tol,
                    g_tol           = o.θ.g_tol,
                    f_tol           = o.θ.f_tol,
                    iterations      = o.θ.iterations,
                    store_trace     = o.θ.store_trace,
                    callback        = x->GrumpsαCallBack( con.A * x + con.Ur, con, e, d, o, oldx, repeatx, solution )
                )
        )
        

        α = Optim.minimizer( result )
        θtr = con.A * α + con.Ur
        θ = getθ( θtr, d )
        Unbalance!( θ, d )

        ObjectiveFunctionα!( fgh, con, zero(T), nothing, nothing, α, δ, e, d, o, s )         # pick up δ
    end
    
    δvec = vcat( δ... )

    Computeβ!( solution, δvec, d )
    @info "computing asymptotic variance if requested"
    @warn "not yet implemented for constrained estimator, so standard errors incorrect (too large)"
    ComputeVξ!( solution, δvec, d )
    SetResult!( solution, θ, δvec, nothing )
    SetConvergence!( solution, result )
    Unbalance!( fgh, d )

    ses!( solution, e, d, fgh, seo )
    
    return solution
end


grumps!( epassed :: Estimator, con :: NoConstraint{T}, d :: Data{T}, o :: OptimizationOptions, θstart :: StartingVector{T}, seo :: StandardErrorOptions; printstructure = true ) where {T<:Flt} = grumps!( epassed, d, o, θstart, seo; printstructure = printstructure )
    




grumps!( e :: Estimator, d :: Data{T}, c :: AbstractConstraint{T}; printstructure = true ) where {T<:Flt} = grumps!( e, d, GrumpsOptimizationOptions(), c, nothing, StandardErrorOptions(); printstructure = printstructure  )
grumps!( e :: Estimator, d :: Data{T}, c :: AbstractConstraint{T}, θstart :: Vec{T}; printstructure = true ) where {T<:Flt} = grumps!( e, d, GrumpsOptimizationOptions(), c, θstart, StandardErrorOptions(); printstructure = printstructure )
grumps!( e :: Estimator, d :: Data{T}, c :: AbstractConstraint{T}, o :: OptimizationOptions; printstructure = true ) where {T<:Flt} = grumps!( e, d, o, c, nothing, StandardErrorOptions(); printstructure = printstructure )
grumps!( e :: Estimator, d :: Data{T}; printstructure = true ) where {T<:Flt} = grumps!( e, d, GrumpsOptimizationOptions(), nothing, StandardErrorOptions(); printstructure = printstructure  )
grumps!( e :: Estimator, d :: Data{T}, θstart :: Vec{T}; printstructure = true ) where {T<:Flt} = grumps!( e, d, GrumpsOptimizationOptions(), θstart, StandardErrorOptions(); printstructure = printstructure )
grumps!( e :: Estimator, d :: Data{T}, o :: OptimizationOptions; printstructure = true ) where {T<:Flt} = grumps!( e, d, o, nothing, StandardErrorOptions(); printstructure = printstructure )


# function grumps( x...; y... )
#     @warn "grumps() is deprecated; use grumps!() instead"
#     return grumps!( x...; y... )
# end


