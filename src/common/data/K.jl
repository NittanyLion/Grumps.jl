






function CreateK( e :: GrumpsMLE , s :: Sources, v :: Variables, dδ :: Int, V :: VarξInput{T}, ::Val{ false }, fap :: Vec{ Vec{ Int } } ) where {T<:Flt}
    return zeros( T, dδ , 0  )
end



function CreateK( e :: Union{ GrumpsPenalized, GrumpsGMM, GrumpsMLE }, s :: Sources, v :: Variables, dδ :: Int, V :: VarξInput{T}, ::Val{ true }, fap :: Vec{ Vec{ Int } } ) where {T<:Flt}


    regs = sort( unique( v.regressors ) )
    inst = sort( unique( v.instruments ) )
    @ensure length( regs ) == length( v.regressors )  "duplication of regressors"
    @ensure length( inst ) == length( v.instruments )  "duplication of instruments"
    if length( regs ) == length( inst )
        @info "exactly identified so there is no penalization"
        return CreateK( GrumpsMDLEEstimatorInstance, s, v, dδ, V, Val( false ), fap )
    end
    @ensure length( regs ) < length( inst ) "underidentification not allowed"
    V == V' || advisory( "the V(ξ) matrix you entered\nis not (perfectly) symmetric" )

    varrat =  6.0 * ( typeof( V ) == UniformScaling{T} ? V[1,1]  : tr( V ) /  size( V, 1 ) ) / ( pi^2 );  0.5 ≤  varrat ≤ 2.0 || @warn "tr( V(ξ) ) / (J V(ε) ) = $varrat"

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

    @ensure HasMaximumColumnRank( [ Ztilde Ctilde ] ) "The columns of your instrument matrix are not linearly independent."
    @ensure HasMaximumColumnRank( [ Xtilde Ctilde ] ) "The columns of your product regressor matrix are not linearly independent."

    C1 = colspace( Ctilde )
    Ztilde -= C1 * (C1'Ztilde)
    Xtilde -= C1 * (C1'Xtilde)    
    Qt = nullspace( Xtilde'Ztilde )
    A = Ztilde * Qt
    R = cholesky( Symmetric( A' * V * A ) )
    return A * inv( R.U )
end


