

"""
    pml_optimize(  
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
function pml_optimize(  f, xstart :: VVector{T}, d::GrumpsData{T}, best :: PMLFGH{T}, options :: NTROptions{T} = NTROptions() ) where {T<:Flt}

    M = length( xstart )
    markets = 1:M
    dδ = dimδm( d )
    ranges = Ranges( dδ )
    K = [ d.plmdata.𝒦[ranges[m],:] for m ∈ markets ]
    plmspace = PLMSpace( dδ, size( K[1], 2 ) )
    ntr = NTR( f, xstart, d.marketdata, K )
    method = NTRMethod( options.ρ_lower, options.ρ_upper, options.Δhat, options.initial_Δ, options.η )
    state = ntr_initial_state( method, ntr, xstart )
    trace = NTRTrace( T )

    ntr_trace!( trace, ntr, state, 0, method, options )
    ntr_best!( ntr, best )

    
    for i ∈ 1:options.iterations
        ntr_update_state!( ntr, state, method, plmspace )
        ntr_trace!( trace, ntr, state, i, method, options )
        ntr_best!( ntr, best )
        x_converged, f_converged, g_converged, f_increased = ntr_assess_convergence( state, ntr, options )
        x_converged || f_converged || g_converged || continue
        return ntr_result!( best, :success )
    end
    return ntr_result!( best, :out_of_iterations )
end


@todo 4 "change return value in pml_optimize to be consistent with the rest of Grumps"