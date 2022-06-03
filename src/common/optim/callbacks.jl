function GrumpsδCallBack( statevec, e, d, o, oldx, repeatx )
    return false
    state = ( typeof( statevec ) <: Vector ) ? statevec[end] : statevec
    # @glog("Grumps ", e, " iteration ", state.iteration, " completed" )
    if true #o.δ.show_trace
        if state.iteration == 0
            printstyled( @sprintf( "%50s\n", name( e ) ); bold = true ) 
            printstyled( @sprintf( "%50s\n", repeat( "_", length( name( e ) ) ) ); bold = true ) 
            printstyled( @sprintf( "%3s   ", "itr" ); bold = true ) 
            printstyled( @sprintf( "%14s   ", "obj fun value" ); color = :red ) 
            printstyled( @sprintf( "%14s   ", "gradient norm" ); color = :blue ) 
            printstyled( @sprintf( "%10s   ", "  time " ); color = :green ) 
            printstyled( @sprintf( "%30s\n", "              delta coefficients" ); color = :magenta ) 
            printstyled( @sprintf( "%3s   ", "---" ); bold = true ) 
            printstyled( @sprintf( "%14s   ", "--------------" ); color = :red ) 
            printstyled( @sprintf( "%14s   ", "--------------" ); color = :blue ) 
            printstyled( @sprintf( "%10s\n", "-------" ); color = :blue ) 
        end      
        printstyled( @sprintf( "%3i   ", state.iteration ); bold = true ) 
        printstyled( @sprintf( "%+14.8f   ", state.value ); color = :red ) 
        printstyled( @sprintf( "%14.8f   ", state.g_norm ); color = :blue ) 
        printstyled( @sprintf( "%7.2f   ", state.metadata["time"] ); color = :green ) 
        try x = state.metadata["x"]
            for i ∈ eachindex( x )
                printstyled( @sprintf( "%+7.2f ", x[i] ); color = :magenta )
            end
            if x ≠ oldx
                repeatx .= 0
            else
                repeatx .+= 1
            end
        catch
        end
    end


    println( )

    # SetHighWaterMark!( solution )   # putting this before garbage collection to get the max
    # GC.gc()

    if isnan( state.g_norm )
        logreport!( solution, "Quitting because NaN achieved" )
        SetStatus!( solution, "NaN" )
        return true
    end
    # return ( repeatx[1] > o.maxrepeats )
    return false
end


function GrumpsθCallBack( statevec, e :: GrumpsEstimator, d :: GrumpsData{T}, o :: GrumpsOptimizationOptions, oldx :: Vec{T}, repeatx :: Vec{Int}, solution :: GrumpsSolution{T} ) where {T<:Flt}
    state = ( typeof( statevec ) <: Vector ) ? statevec[end] : statevec
    # @glog("Grumps ", e, " iteration ", state.iteration, " completed" )
    if o.θ.show_trace
        if state.iteration == 0
            printstyled( @sprintf( "%50s\n", name( e ) ); bold = true ) 
            printstyled( @sprintf( "%50s\n", repeat( "_", length( name( e ) ) ) ); bold = true ) 
            printstyled( @sprintf( "%3s   ", "itr" ); bold = true ) 
            printstyled( @sprintf( "%14s   ", "obj fun value" ); color = :red ) 
            printstyled( @sprintf( "%14s   ", "gradient norm" ); color = :blue ) 
            printstyled( @sprintf( "%10s   ", "  time " ); color = :green ) 
            printstyled( @sprintf( "%30s\n", "        theta coefficients" ); color = :magenta ) 
            printstyled( @sprintf( "%3s   ", "---" ); bold = true ) 
            printstyled( @sprintf( "%14s   ", "--------------" ); color = :red ) 
            printstyled( @sprintf( "%14s   ", "--------------" ); color = :blue ) 
            printstyled( @sprintf( "%10s\n", "-------" ); color = :blue ) 
        end      
        printstyled( @sprintf( "%3i   ", state.iteration ); bold = true ) 
        printstyled( @sprintf( "%+14.8f   ", state.value ); color = :red ) 
        printstyled( @sprintf( "%14.8f   ", state.g_norm ); color = :blue ) 
        printstyled( @sprintf( "%7.2f   ", state.metadata["time"] ); color = :green ) 
        try x = state.metadata["x"]
            θ = getθ( x, d )
            Unbalance!( θ, d )
            for i ∈ eachindex( x )
                printstyled( @sprintf( "%+7.2f ", θ[i] ); color = :magenta )
            end
            if isapprox( x, oldx; atol = max( o.θ.x_tol, 1.0e-10 ) )
                repeatx .+= 1
            else
                repeatx .= 0
            end
            copyto!( oldx, x )
        catch
        end
        # println( "g= ",state.metadata["g(x)"] )
        # println( "H = ", state.metadata["h(x)"] )
    end


    println( )

    SetHighWaterMark!( solution )   # putting this before garbage collection to get the max
    # GC.gc()

    if isnan( state.g_norm )
        logreport!( solution, "Quitting because NaN achieved" )
        SetStatus!( solution, "NaN" )
        return true
    end
    return ( repeatx[1] > o.maxrepeats )
end
