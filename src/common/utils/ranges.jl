"""
    SplitEqually( M, n )

Splits M tasks equally over n workers.  The function
returns at most n ranges.  It will return n ranges if
M ≥ n.  Otherwise it will return M single element ranges.
"""
function SplitEqually(  M :: Int, n :: Int ) 
    if M ≤ n
        return [j:j for j ∈ 1:M ]
    end
    rat, rest  = divrem( M, n )
    ranges = Vector{UnitRange{Int32}}( undef, n )
    for j ∈ 1:n
        t = j * rat
        if j ≤ rest
            ranges[j] = t + j - rat : t + j
        else
            ranges[j] = t + rest - rat + 1 :  t + rest
        end
    end
    return ranges
end

"""
    StartFinish!( start::Vec{Int}, finish::Vec{Int}, dimensions::Vec{Int} )
    

"""
function StartFinish!( start::Vec{Int}, finish::Vec{Int}, dimensions::Vec{Int} )
    start[1] = 1;  finish[1] = dimensions[1]
    for m ∈ 2: length( dimensions )
        start[m] = finish[m-1] + 1
        finish[m] = finish[m-1] + dimensions[m]
    end
    return nothing
end


function StartFinish( dimensions::Vec{Int} )
    M = length( dimensions )
    start = zeros( Int, M );  finish = zeros( Int, M )
    StartFinish!( start, finish, dimensions )
    return start, finish 
end


StartFinish( v ) = StartFinish( [ length(x) for x ∈ v ] )


function Ranges( dimensions::Vector{Int})
    (start, finish) = StartFinish( dimensions )
    return [ start[m]:finish[m] for m ∈ eachindex(dimensions) ]
end


Ranges( v ) = Ranges( [ length(x) for x ∈ v ]  )



function sizes( x )
    x == nothing ? nothing : size(x)
end


function sizes( F, G, H, δ )
    sizes(F), sizes(G), sizes(H), sizes(δ)
end
