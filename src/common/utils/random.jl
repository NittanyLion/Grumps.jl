# using StableRNGs


function RandomNumberGenerators( ::Val{false}, n :: Int; seed = 2 )
    Random123.seed!( seed )
    rngs = Vec{ Threefry4x{UInt64,32} }( undef, n )
    per = div( typemax( UInt32 ), n ) 
    for i ∈ 0: n-1
        rngs[i+1] = Threefry4x( ( 0, 0, 0, i ), 32 )
        Random123.set_counter!( rngs[i+1], 1 )
    end
    return rngs
end


function RandomNumberGenerators( ::Val{true}, n :: Int; seed = 2 )
    # r = StableRNG( seed )
    # [ StableRNG( rand(r, UInt)  ) for j ∈ 1: n ]
    advisory( "no separate random number generator implemented for replicable = true; just using the first one" )
    RandomNumberGenerators( Val( false ), n; seed = seed )
end


"""
    RandomNumberGenerators( n; seed = 2 )

Initializes n random number generators to be used on parallel threads with the specified seed using the Threefry4x algorithm.
"""
function RandomNumberGenerators( n :: Int; seed = 2, replicable = false )
    RandomNumberGenerators( Val( replicable  ), n; seed = seed )
end