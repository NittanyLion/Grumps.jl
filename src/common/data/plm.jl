

@todo 2 "make CreateK more efficient"

function CreateK( e :: GrumpsMLE, s :: Sources, v :: Variables, dδ :: Int, σ2 :: T, ::Val{ false }, fap :: Vec{ Vec{Int} } ) where {T<:Flt}
    # return typeof( e ) ≠ GrumpsCheapEstimator ? zeros( T, dδ , 0  ) : CreateK( GrumpsPMLEstimatorInstance, s, v, dδ, σ2, Val( true ), fap ) 
    return zeros( T, dδ , 0  )
end

@todo 2 "there is duplication in CreateK versus the function below"
@todo 3 "the functions in this file should be checked carefully, especially CreateK"

function CreateK( e :: Union{ GrumpsPenalized, GrumpsGMM, GrumpsMLE }, s :: Sources, v :: Variables, dδ :: Int, σ2 :: T, ::Val{ true }, fap :: Vec{ Vec{ Int } } ) where {T<:Flt} 

    @info "creating 𝒦, as expected "

    regs = sort( unique( v.regressors ) )
    inst = sort( unique( v.instruments ) )
    @ensure length( regs ) == length( v.regressors )  "duplication of regressors"
    @ensure length( inst ) == length( v.instruments )  "duplication of instruments"
    if length( regs ) == length( inst )
        @info "exactly identified so there is no penalization"
        return CreateK( GrumpsVanillaEstimatorInstance, s, v, dδ, σ2, Val( false ), fap )
    end
    @ensure length( regs ) < length( inst ) "underidentification not allowed"

    inboth = intersect( regs, inst )
    onlyregs = setdiff( regs, inboth )
    onlyinst = setdiff( inst, inboth )
    @ensure v.nuisancedummy ∉ union( regs, inst, v.dummies )  "nuisance dummy should not be included in the regressors and instruments"
    
    dumsunsorted, = ExtractDummiesFromDataFrame( T, s.products, v.dummies )
    𝒹unsorted = v.nuisancedummy == :none ? nothing : ExtractVectorFromDataFrame( s.products, v.nuisancedummy )
    𝒳tildeunsorted = ExtractMatrixFromDataFrame( T, s.products, onlyregs )
    𝒵tildeunsorted = ExtractMatrixFromDataFrame( T, s.products, onlyinst )
    Ctildeunsorted = ExtractMatrixFromDataFrame( T, s.products, inboth )
    
    dinboth, dregs, dinst, ddums = length( inboth ), length( onlyregs ), length( onlyinst ), size( dumsunsorted, 2 )

    
    
    Ctilde = zeros( T, dδ, dinboth + ddums )
    Xtilde = zeros( T, dδ, dregs )
    Ztilde = zeros( T, dδ, dinst )
    𝒹 = v.nuisancedummy == :none ? nothing :  similar( 𝒹unsorted )

    markets = 1:length( fap )
    ranges = Ranges( fap )
    for m ∈ markets
        if dregs > 0
            Xtilde[ ranges[m], : ] = 𝒳tildeunsorted[ fap[m], :]
        end
        if dinst > 0
            Ztilde[ ranges[m], : ] = 𝒵tildeunsorted[ fap[m], : ]
        end
        if dinboth > 0
            Ctilde[ ranges[m], 1 : dinboth ] = Ctildeunsorted[ fap[m], : ]
            Ctilde[ ranges[m], dinboth + 1 : dinboth + ddums ] = dumsunsorted[ fap[m], : ]
        end
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
            zsum = sum( Ztilde[ ind, : ]; dims = 1 ) / length( ind )
            for 𝒶 ∈ eachindex( zsum )
                Ztilde[ ind, 𝒶 ] .-= zsum[ 𝒶 ]
            end 
            xsum = sum( Xtilde[ ind, : ]; dims = 1 ) / length( ind )
            for 𝒶 ∈ eachindex( xsum )
                Xtilde[ ind, 𝒶 ] .-= xsum[ 𝒶 ]
            end 
            csum = sum( Ctilde[ ind, : ]; dims = 1 ) / length( ind )
            for 𝒶 ∈ eachindex( csum )
                Ctilde[ ind, 𝒶 ] .-= csum[ 𝒶 ]
            end 
        end
    end

    

    @ensure rank( Ctilde ) == size( Ctilde, 2 )  "collinearity in regressors common to X,Z"

    if dinboth > 0
        Q = inv( Ctilde' * Ctilde )
        Ztilde = Ztilde - Ctilde * Q * Ctilde' * Ztilde
        Xtilde = Xtilde - Ctilde * Q * Ctilde' * Xtilde
    end
    UZ, = svd( Ztilde; alg = LinearAlgebra.QRIteration() )
    UX, = svd( Xtilde; alg = LinearAlgebra.QRIteration() )

    V = dregs > 0 ? UZ * nullspace( UX'UZ ) : UZ

    @ensure rank( V ) == dinst - dregs "underidentified"
    return V / sqrt( σ2 )
end




function GrumpsPLMData( id :: Any, e :: Estimator, s :: Sources, v :: Variables, fap :: Vec{ Vec{Int} }, usepenaltyterm :: Bool, σ2 :: T ) where {T<:Flt}
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

    𝒦 = CreateK( e, s, v, dδ, T(σ2), Val( usepenaltyterm ), fap )
    return GrumpsPLMData( 𝒳, 𝒳̂, vcat( String.( v.regressors ), dumbnames ), size(𝒵,2), 𝒦,  σ2 )
end

PLMData( x...; y... ) = GrumpsPLMData(x...; y...)
export PLMData

