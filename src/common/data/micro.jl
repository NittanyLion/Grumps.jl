# The functions below are used to create data objects for the micro likelihood.



"""
    CreateChoices( 
        id          :: Any,
        dfc         :: AbstractDataFrame, 
        v           :: Variables, 
        products    :: Vec{<:AbstractString} 
        )

    CreateChoices reads data from a dataframe and turns them into an integer vector y and a 
    Boolean matrix Y of choices.  
"""
function CreateChoices( ::Any, dfc :: AbstractDataFrame, v :: Variables, products :: Vec{<:AbstractString} )
    MustBeInDF( v.choice, dfc, "consumer data frame" ) 

    S = nrow( dfc ) :: Int
    y = zeros( Int, S ) 
    J = length( products )
    Y = fill( false, S, J )
    for i ∈ 1:S
        y[i] = findstringinarray( dfc[i,v.choice], products, "cannot find product $(dfc[i,v.choice]) in list of products" )
        Y[i,y[i]] = true
    end
    return y, Y
end






"""
    CreateInteractions( 
        id          :: Any,
        dfc         :: AbstractDataFrame, 
        dfp         :: AbstractDataFrame, 
        v           :: Variables, 
        T           = F64 
        )
        
    CreateInteractions reads data from consumer and product dataframes and returns an array of interactions.
"""
function CreateInteractions( id ::Any, dfc:: AbstractDataFrame, dfp:: AbstractDataFrame, v :: Variables, T :: Type{ 𝒯 }= F64 ) where 𝒯 <: Flt
    MustBeInDF( v.interactions[:,1], dfc, "consumer data frame" )
    MustBeInDF( v.interactions[:,2], dfp, "product data frame" )
    isdefined( Main, :InteractionsCallback! ) && return CreateInteractions( Val( :GrumpsInteractions! ), dfc, dfp, v, T )
    isdefined( Main, :InteractionsCallback ) && return CreateInteractions( Val( :GrumpsInteractions ), dfc, dfp, v, T )


    S = nrow( dfc ) 
    J = nrow( dfp ) + 1
    dθz = size( v.interactions, 1 ) :: Int
    Z = zeros( T, S, J, dθz )
    for t ∈ 1:dθz, j ∈ 1:J-1, i ∈ 1: S
        Z[i,j,t] = T( dfc[i, v.interactions[t,1] ] * dfp[j, v.interactions[t,2] ] ) :: T
    end
    return Z
end



function CreateInteractions( ::Val{:GrumpsInteractions}, dfc :: AbstractDataFrame, dfp :: AbstractDataFrame, v :: Variables, T :: Type{ 𝒯 } = F64 ) where 𝒯 <: Flt
    MustBeInDF( v.interactions[:,1], dfc, "consumer data frame" )
    MustBeInDF( v.interactions[:,2], dfp, "product data frame" )
    S = nrow( dfc ); J = nrow( dfp) + 1; dθz = size( v.interactions, 1 )

    local Vc = [ dfc[ i, v.interactions[t, 1] ] for i ∈ 1:S, t ∈ 1:dθz ]
    local Vp = [ dfp[ j, v.interactions[t ,2] ] for j ∈ 1:J-1, t ∈ 1:dθz ]
    Z = zeros( T, S, J, dθz )

    for t ∈ 1:dθz, j ∈ 1:J-1, i ∈ 1:S
        Z[i,j,t] = Main.InteractionsCallback( Vc, Vp, i, j, t, :micro, dfc[ 1, v.market ], dfp[ :, v.product ]  )
    end
    return Z
end



function CreateInteractions( ::Val{:GrumpsInteractions!}, dfc :: AbstractDataFrame, dfp :: AbstractDataFrame, v :: Variables, T :: Type{ 𝒯 }= F64 ) where 𝒯 <: Flt
    MustBeInDF( v.interactions[:,1], dfc, "consumer data frame" )
    MustBeInDF( v.interactions[:,2], dfp, "product data frame" )
    S = nrow( dfc ); J = nrow( dfp) + 1; dθz = size( v.interactions, 1 )

    Vc = [ dfc[ i, v.interactions[t, 1] ] for i ∈ 1:S, t ∈ 1:dθz ]
    Vp = [ dfp[ j, v.interactions[t ,2] ] for j ∈ 1:J-1, t ∈ 1:dθz ]
    Z = zeros( T, S, J, dθz )
    Main.InteractionsCallback!( Z, Vc, Vp, :micro, dfc[ 1, v.market ], dfp[ :, v.product ]  )
    return Z
end




"""
    CreateMicroInstruments( 
        id          :: Any,
        dfc         :: AbstractDataFrame, 
        dfp         :: AbstractDataFrame, 
        v           :: Variables, 
        usesmicmom  :: Bool, 
        T = F64 
        )

    CreateMicroInstruments is used for the MSM version of our estimator, which is not recommended.
"""
function CreateMicroInstruments( ::Any, dfc:: AbstractDataFrame, dfp:: AbstractDataFrame, v :: Variables, usesmicmom :: Bool, T :: Type{ 𝒯 }= F64 ) where 𝒯 <: Flt
    S, dδ = nrow( dfc ), nrow( dfp ) 
    J = dδ + 1
    micinst = size( v.microinstruments, 1 ) == 0 ? v.interactions : v.microinstruments
    moms = size( micinst, 1 )
    if moms == 0 || !usesmicmom
        return zeros( T, S, dδ, 0 )
    end
    MustBeInDF( micinst[:,1], dfc, "consumer data frame" )
    MustBeInDF( micinst[:,2], dfp, "product data frame" )

    ℳ = zeros( T, S, dδ + 1, moms )
    for t ∈ 1:moms, j ∈ 1:dδ, i ∈ 1:S
        ℳ[i,j,t] = dfc[i, micinst[t,1] ] * dfp[j, micinst[t,2] ]
    end
    # now replace ℳ with ℳ (ℳ'ℳ)^{-1/2}
    # I've tested this
    ℛ = reshape( ℳ, S * J, moms )
    𝒮 = svd( ℛ; alg = LinearAlgebra.QRIteration() )
    ℳ = reshape( 𝒮.U * 𝒮.Vt, S, J, moms )
    return ℳ
end


"""
    CreateRandomCoefficients( 
        idstub      :: Any,
        dfp         :: AbstractDataFrame, 
        v           :: Variables, 
        nw          :: NodesWeights, 
        T            = F64 
        )

    CreateRandomCoefficients takes a dataframe and random draws and turns it into random coefficients data.   
"""
function CreateRandomCoefficients( ::Any, dfp :: AbstractDataFrame, v :: Variables, nw :: NodesWeights, T :: Type{ 𝒯 }= F64 ) where 𝒯 <: Flt
    MustBeInDF( v.randomcoefficients, dfp, "product data frame" )
    R = length( nw.weights )
    dθν = length( v.randomcoefficients )
    @ensure size( nw.nodes, 2 ) ≥ dθν  "you have specified fewer dimensions in the nodes than there are random coefficients"
    J = nrow( dfp ) + 1
    X = zeros( R, J, dθν )
    for t ∈ 1:dθν, j ∈ 1:J - 1, r ∈ 1:R
        X[r,j,t] = dfp[ j, v.randomcoefficients[t] ] * nw.nodes[r,t]
    end
    return X
end

function CreateRandomCoefficients( ::Any, dfp :: AbstractDataFrame, v :: Variables, nw :: MSMMicroNodesWeights, T :: Type{ 𝒯 }= F64 ) where 𝒯 <: Flt
    MustBeInDF( v.randomcoefficients, dfp, "product data frame" )
    R,S = size( nw.weights )
    dθν = length( v.randomcoefficients )
    @ensure size( nw.nodes, 3 ) ≥ dθν  "you have specified fewer dimensions in the nodes than there are random coefficients"
    J = nrow( dfp ) + 1
    X = zeros( R, S, J, dθν )
    for t ∈ 1:dθν, j ∈ 1:J - 1, r ∈ 1:R, i ∈ 1:S
        X[r,i,j,t] = dfp[ j, v.randomcoefficients[t] ] * nw.nodes[r,i,t]
    end
    return X
end




function GrumpsMicroDataMode( id :: Any, dfp, mkt, nw :: NodesWeights, T, v, y, Y, Z, ℳ, ::Val{:Hog} )
    X = CreateRandomCoefficients( id, dfp, v, nw, T )
    return size(Z,1) > 0 ? GrumpsMicroDataHog( String(mkt), Z, X, y, Y, nw.weights, ℳ ) : GrumpsMicroNoData( String(mkt) )
end





function GrumpsMicroDataMode( id ::Any, dfp, mkt, nw :: NodesWeights, T, v, y, Y, Z, ℳ, ::Val{:Ant} )
    𝒳 = ExtractMatrixFromDataFrame( T, dfp, v.randomcoefficients )
    𝒟 = nw.nodes
    return size(Z,1) > 0 ? GrumpsMicroDataAnt{T}( String(mkt), Z, 𝒳, 𝒟, y, Y, nw.weights, ℳ ) : GrumpsMicroNoData{T}( String(mkt) )
end


function GrumpsMicroDataMode( ::Any, dfp, mkt, nw :: NodesWeights, T, v, y, Y, Z, ℳ, anyval )
    @ensure false "memory mode you chose is not programmed in GrumpsMicroDataMode"
end



function GrumpsMicroData( 
    id :: Any,
    mkt :: AbstractString,
    dfc :: AbstractDataFrame,
    dfp :: AbstractDataFrame, 
    v :: Variables, 
    nw :: NodesWeights,
    rng :: AbstractRNG, 
    o :: DataOptions,
    usesmicmom :: Bool,
    m  :: Int,
    T :: Type{ 𝒯 } = F64
    ) where 𝒯 <: Flt

    MustBeInDF( v.choice, dfc, "consumer" ) 
    MustBeInDF( v.product, dfp,  "product" ) 
    products = vcat( String.( string.(  dfp[ :, v.product ] ) ), String( string( v.outsidegood  ) ) ) :: Vector{ String }
    @ensure NoDuplicates( products ) "unexpected duplicates in $products"
    y, Y = CreateChoices( id, dfc, v, products )

    Z = CreateInteractions( id, dfc, dfp, v, T )
    ℳ = CreateMicroInstruments(  id, dfc, dfp, v, usesmicmom, T )

    return GrumpsMicroDataMode(  id, dfp, mkt, nw, T, v, y, Y, Z, ℳ, Val( micromode(o) ) )
end

MicroData(x...; y...) = GrumpsMicroData(x...; y...)
MicroDataMode(x...; y...) = GrumpsMicroDataMode(x...; y...)
export MicroData, MicroDataMode

