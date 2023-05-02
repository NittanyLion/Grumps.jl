# The functions below are used to create data objects for the micro likelihood.



"""
    CreateChoices( 
        dfc         :: AbstractDataFrame, 
        v           :: Variables, 
        products    :: Vec{<:AbstractString} 
        )

    CreateChoices reads data from a dataframe and turns them into an integer vector y and a 
    Boolean matrix Y of choices.  
"""
function CreateChoices( dfc :: AbstractDataFrame, v :: Variables, products :: Vec{<:AbstractString} )
    MustBeInDF( v.choice, dfc, "consumer data frame" ) 

    S = nrow( dfc )
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
        dfc         :: AbstractDataFrame, 
        dfp         :: AbstractDataFrame, 
        v           :: Variables, 
        T           = F64 
        )
        
    CreateInteractions reads data from consumer and product dataframes and returns an array of interactions.
"""
function CreateInteractions( dfc:: AbstractDataFrame, dfp:: AbstractDataFrame, v :: Variables, T = F64 )
    MustBeInDF( v.interactions[:,1], dfc, "consumer data frame" )
    MustBeInDF( v.interactions[:,2], dfp, "product data frame" )

    S = nrow( dfc )
    J = nrow( dfp ) + 1
    dθz = size( v.interactions, 1 )
    Z = zeros( T, S, J, dθz )
    for t ∈ 1:dθz, j ∈ 1:J-1, i ∈ 1:S
        Z[i,j,t] = dfc[i, v.interactions[t,1] ] * dfp[j, v.interactions[t,2] ]
    end
    return Z
end

"""
    CreateMicroInstruments( 
        dfc         :: AbstractDataFrame, 
        dfp         :: AbstractDataFrame, 
        v           :: Variables, 
        usesmicmom  :: Bool, 
        T = F64 
        )

    CreateMicroInstruments is used for the MSM version of our estimator, which is not recommended.
"""
function CreateMicroInstruments( dfc:: AbstractDataFrame, dfp:: AbstractDataFrame, v :: Variables, usesmicmom :: Bool, T = F64 )
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
        dfp         :: AbstractDataFrame, 
        v           :: Variables, 
        nw          :: NodesWeights, 
        T            = F64 
        )

    CreateRandomCoefficients takes a dataframe and random draws and turns it into random coefficients data.   
"""
function CreateRandomCoefficients( dfp :: AbstractDataFrame, v :: Variables, nw :: NodesWeights, T = F64 )
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

function CreateRandomCoefficients( dfp :: AbstractDataFrame, v :: Variables, nw :: MSMMicroNodesWeights, T = F64 )
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


function CreateUserInteractions( u :: DefaultUserEnhancement,  dfc :: AbstractDataFrame, dfp :: AbstractDataFrame, v :: Variables, T = F64 )
    return zeros( T, 0, 0, 0 ) 
end

function CreateUserRandomCoefficients( u :: DefaultUserEnhancement, dfp :: AbstractDataFrame, v :: Variables, nw :: NodesWeights, T = F64 )
    return zeros( T, 0, 0, 0 )
end

function CreateUserRandomCoefficients( u :: DefaultUserEnhancement, dfp :: AbstractDataFrame, v :: Variables, nw :: MSMMicroNodesWeights, T = F64 )
    return zeros( T, 0, 0, 0, 0 )
end


function GrumpsMicroDataMode( dfp, mkt, nw :: NodesWeights, T, u, v, y, Y, Z, ℳ, ::Val{:Hog} )
    X = CreateRandomCoefficients( dfp, v, nw, T )
    X2 = CreateUserRandomCoefficients( u, dfp, v, nw, T )
    if size( X2, 3 ) > 0
        @ensure size(X,1) == size(X2,1)  "user-created random coefficient matrix has the wrong first dimension"
        @ensure size(X,2) == size(X2,2)  "user-created random coefficient matrix has the wrong second dimension"
        X = cat( X, X2; dims = size(X,4) )
    end
    return size(Z,1) > 0 ? GrumpsMicroDataHog( String(mkt), Z, X, y, Y, nw.weights, ℳ ) : GrumpsMicroNoData( String(mkt) )
end





function GrumpsMicroDataMode( dfp, mkt, nw :: NodesWeights, T, u, v, y, Y, Z, ℳ, ::Val{:Ant} )
    @ensure typeof( u ) <: DefaultUserEnhancement  "Cannot have micro memory mode Ant with user enhancements"
    𝒳 = ExtractMatrixFromDataFrame( T, dfp, v.randomcoefficients )
    𝒟 = nw.nodes
    return size(Z,1) > 0 ? GrumpsMicroDataAnt{T}( String(mkt), Z, 𝒳, 𝒟, y, Y, nw.weights, ℳ ) : GrumpsMicroNoData{T}( String(mkt) )
end


function GrumpsMicroDataMode( dfp, mkt, nw :: NodesWeights, T, u, v, y, Y, Z, ℳ, anyval )
    @ensure false "memory mode you chose is not programmed in GrumpsMicroDataMode"
end


function GrumpsMicroData( 
    mkt :: AbstractString,
    dfc :: AbstractDataFrame,
    dfp :: AbstractDataFrame, 
    v :: Variables, 
    nw :: NodesWeights,
    rng :: AbstractRNG, 
    o :: DataOptions,
    usesmicmom :: Bool,
    T = F64, 
    u :: UserEnhancement = DefaultUserEnhancement()
    )

    MustBeInDF( v.choice, dfc, "consumer" ) 
    MustBeInDF( v.product, dfp,  "product" ) 
    products = String.( string.( vcat( dfp[ :, v.product ] , v.outsidegood ) ) ) 
    @ensure NoDuplicates( products ) "unexpected duplicates in $products"

    y, Y = CreateChoices( dfc, v, products )

    Z = CreateInteractions( dfc, dfp, v, T )
    Z2 = CreateUserInteractions( u, dfc, dfp, v, T )
    if size(Z2,3) > 0
        @ensure size(Z,1) == size(Z2,1) "user-created interactions matrix has the wrong first dimension"
        @ensure size(Z,2) == size(Z2,2) "user-created interactions matrix has the wrong first dimension"
        Z = cat( Z, Z2; dims = 3 )
    end

    ℳ = CreateMicroInstruments( dfc, dfp, v, usesmicmom, T )

    return GrumpsMicroDataMode( dfp, mkt, nw, T, u, v, y, Y, Z, ℳ, Val( micromode(o) ) )
end


