

"""
    function NoDuplicates( x  )

Checks for duplicates in the array x and returns a boolean.
"""
function NoDuplicates( x :: Array{<:Any} )
    length( unique( x ) ) == length( x )
end


"""
    findinarray( needle, haystack, message )

Finds needle in the array haystack and if found returns its index.  If not found, it throws an error.
"""
function findinarray( needle, haystack, message )
    ff = findfirst( x->x == needle, haystack )
    ff == nothing && throwargerr( message ) 
    return ff
end


function findstringinarray( needle, haystack, message )
    typeof( needle ) == String || return findinarray( string(needle), haystack, message )
    eltype( haystack ) == String && return findinarray( needle, haystack, message )
    ff = findfirst( x->string(x) == needle, haystack )
    ff == nothing && throwargerr( message ) 
    return ff
end


safesum( x ) = sum( x; init = zero( eltype(x) ) )
safeminimum( x ) = minimum( x; init = zero( eltype(x) ) )
safemaximum( x ) = maximum( x; init = zero( eltype(x) ) )
