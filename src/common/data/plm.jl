




function GrumpsPLMData( id :: Any, e :: Estimator, s :: Sources, v :: Variables, fap :: Vec{ Vec{Int} }, usepenaltyterm :: Bool, V :: VarξInput{T}, template :: VarξTemplate )  where {T<:Flt}
    @ensure isa( s.products, DataFrame )   "was expecting a DataFrame for product data"
        
    ( dumsunsorted, dumbnames ) = ExtractDummiesFromDataFrame( T, s.products, v.dummies )
    𝒹unsorted = v.nuisancedummy == :none ? nothing : ExtractVectorFromDataFrame( s.products, v.nuisancedummy ) 
    𝒳unsorted = ExtractMatrixFromDataFrame( T, s.products, v.regressors )
    𝒵unsorted = ExtractMatrixFromDataFrame( T, s.products, v.instruments )
    nregs = length( v.regressors )
    ninst = length( v.instruments )
    dδ = size(𝒳unsorted,1)
    𝒳 = zeros( T, dδ, size(𝒳unsorted,2) + size(dumsunsorted,2) )
    𝒵 = zeros( T, dδ, length( v.instruments) + size(dumsunsorted,2) )
    𝒹 = v.nuisancedummy == :none ? nothing :  similar( 𝒹unsorted )

    ranges = Ranges( fap )
    for m ∈ eachindex( fap )
        𝒳[ ranges[m], 1:nregs ] = 𝒳unsorted[ fap[m] , :]
        𝒳[ ranges[m], nregs+1:end ] = dumsunsorted[ fap[m], : ]
        𝒵[ ranges[m], 1:ninst ] = 𝒵unsorted[ fap[m], : ]
        𝒵[ ranges[m], ninst+1:end] = dumsunsorted[ fap[m], : ]
        if v.nuisancedummy ≠ :none
             𝒹[ ranges[m] ] = 𝒹unsorted[ fap[m] ]
        end
    end 

    if 𝒹 ≠ nothing
        # difference out nuisance dummies
        u = sort( unique( 𝒹unsorted ) )
        nd = length( u ) - 1
        @ensure nd  > 0   "nuisance dummy should take more than one value"
        for t ∈ 1:nd 
            ind = findall( x->x == u[t], 𝒹 )
            zsum = sum( 𝒵[ ind, : ]; dims = 1 ) / length( ind )
            for 𝒶 ∈ eachindex( zsum )
                𝒵[ ind, 𝒶 ] .-= zsum[1,𝒶] 
            end
        end
    end 
    𝒳̂ = 𝒵 * ( 𝒵 \ 𝒳 )

    𝒦 = CreateK( e, s, v, dδ, V, Val( usepenaltyterm ), fap )
    return GrumpsPLMData( 𝒳, 𝒳̂, vcat( String.( v.regressors ), dumbnames ), size(𝒵,2), 𝒦, template )
end

PLMData( x...; y... ) = GrumpsPLMData(x...; y...)
export PLMData


function Template( id :: Any, :: VarξHomoskedastic, dfp :: DataFrame, fap :: Vec{ Vec{Int} } ) 
    @info "will compute ξ variance matrix for next stage assuming homoskedasticity"
    J = length( fap )
    return spzeros( Bool, J, J )
end

function Template( id :: Any, :: VarξHeteroskedastic, dfp :: DataFrame, fap :: Vec{ Vec{Int} } ) 
    @info "will compute ξ variance matrix for next stage assuming heteroskedasticity"
    J = sum( length( fap[m] ) for m ∈ eachindex( fap ) )
    return sparse( I, J, J )
end

function Template( id :: Any, ou :: VarξClustering, dfp :: DataFrame, fap :: Vec{ Vec{Int} } ) 
    clon = clusteron( ou )
    @info "will compute ξ variance matrix for next stage assuming clustering on $clon"
    MustBeInDF( clon, dfp, "products" )

    A = Matrix{Int64}(undef, 0, 2)
    dumsunsorted = ExtractDummiesFromDataFrameNoDrop( Bool, dfp, [clon] )
    dums = similar( dumsunsorted )
    ranges = Ranges( fap )
    for m ∈ eachindex( fap )
        dums[ranges[m],:] = dumsunsorted[fap[m],:]
    end
    for c ∈ axes( dums, 2 )
        v = findall( dums[:,c] )
        for i ∈ v, j ∈ v
            A = vcat( A, [i j ] )
        end
    end

    J = sum( length( fap[m] ) for m ∈ eachindex( fap ) )
    if size(A,1)  > J^1.2
        @warn "you are doing a 💩load of clustering: smaller cluster sizes would be advisable"
    end
    S = sparse( A[:,1], A[:,2], fill(true, size(A,1) ) )
    return S
end


Template( id :: Any, options :: DataOptions, dfp :: DataFrame, fap :: Vec{ Vec{Int} } ) = 
    Template( id, VarξOutput( options ), dfp, fap )
