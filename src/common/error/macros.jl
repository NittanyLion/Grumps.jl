macro ensure( cond, msg )
    local lcond = esc( cond )
    local lmsg = esc( msg )
    return :( $lcond ? nothing : throwargerr( $lmsg ) )
end


macro warnif( cond, msg )
    local lcond = esc( cond )
    local lmsg = esc( msg )
    return :( !$lcond ? nothing : @warn $msg  )
end


# macro ensurefloat( T )
#     return :( @ensure( $T <: AbstractFloat, "was expecting a floating point type" ) )
# end


# macro ensureint( T )
#     return :( @ensure( $T <: Int, "was expecting an integer type" ) )
# end


# macro ensuretype( T, T2 )
#     println( "$T  $T2")
#     return :( @ensure( $T2 <: $T, string("was expecting type ", $T ) ) )
# end

# macro ensure( cond, msg )
#     return :( assert( $cond, $msg) )
# end

# const ensure = @assert