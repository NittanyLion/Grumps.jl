

"""
    RandomNumberGenerators( n; seed = 2 )

Initializes n random number generators to be used on parallel threads with the specified seed using the Threefry4x algorithm.
"""
function RandomNumberGenerators( n :: Int; seed = 2 )
    Random123.seed!( seed )
    rngs = Vec{ Threefry4x{UInt64,32} }( undef, n )
    per = div( typemax( UInt32 ), n ) 
    for i ∈ 0: n-1
        rngs[i+1] = Threefry4x( ( per * i, per * i, per * i, per * i ), 32 )
        Random123.set_counter!( rngs[i+1], 1 )
    end
    return rngs
end