

"""
    cleer_optimize(  
        f, 
        xstart, 
        d, 
        best, 
        options
        )

Does a penalized maximum likelihood optimization using objective function *f*, starting vector *xstart*, data *d*, information on objective function
and derivatives *best*, and options *options*.  *xstart* should be a vector of vectors of floats of type T, *d* a data structure of type GrumpsData{T},
*best* a structure of type *NTRFGH{T}* and options a structure of type *NTROptions{T}*.

This function should only be used if you know what you are doing; it is an internal object.
"""
function cleer_optimize(  f, xstart :: VVector{T}, d::GrumpsData{T}, best :: PMLFGH{T}, options :: NewterOptions{T} = NewterOptions() ) where {T<:Flt}

    M = length( xstart )
    markets = 1:M
    dδ = dimδm( d )
    ranges = Ranges( dδ )
    K = [ d.plmdata.𝒦[ranges[m],:] for m ∈ markets ]
    # plmspace = PLMSpace( dδ, size( K[1], 2 ) )
    newt = Newter( f, xstart, d.marketdata, K )
    method = NewterMethod( options.ρ̲, options.ρ̄, options.Δ̂, options.initial_Δ, options.η )
    state = NewterInitialState( method, newt, xstart )
    trace = NewterTrace( T )

    NewterTrace!( trace, newt, state, 0, method, options )
    NewterBest!( newt, best )

    
    for i ∈ 1:options.iterations
        NewterUpdateState!( newt, state, method )
        NewterTrace!( trace, newt, state, i, method, options )
        NewterBest!( newt, best )
        x_converged, f_converged, g_converged, f_increased = NewterAssessConvergence( state, newt, options )
        x_converged || f_converged || g_converged || continue
        @debug "found δ solution"
        return NewterResult!( best, :success )
    end
    @debug "ran out of δ iterations  ($(options.iterations))"
    return NewterResult!( best, :out_of_iterations )
end

