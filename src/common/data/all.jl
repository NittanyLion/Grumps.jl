
"""
    GrumpsData( 
        e                   :: GrumpsEstimator,
        ss                  :: Sources,
        v                   :: Variables,
        integrators         :: GrumpsIntegrators = BothIntegrators(),
        T                   :: Type = F64,
        u                   :: UserEnhancement = DefaultUserEnhancement();
        options             :: DataOptions = GrumpsDataOptions()
        )

Takes user inputs and converts them into an object that Grumps can understand.  This is synonymous with Data(...).

*GrumpsData* takes the following arguments, of which the first three are mandatory:

* *e*:                   estimator; see *Estimator*
* *ss*:                  cata sources; see *Sources*
* *v*:                   variables to be used; see *Variables*
* *integrators*:            see *BothIntegrators*, *DefaultMicroIntegrator*, and *DefaultMacroIntegrator*
* *T*:                   floating point type; not heavily tested
* *u*:                   not yet implemented
* *options*:             data options to be used, see *DataOptions*
"""
function GrumpsData( 
    e                   :: GrumpsEstimator,
    ss                  :: Sources,
    v                   :: Variables,
    integrators            :: GrumpsIntegrators = BothIntegrators(),
    T                   :: Type = F64,
    u                   :: UserEnhancement = DefaultUserEnhancement();
    options             :: DataOptions = GrumpsDataOptions()
    )

    # read data from file if not already done
    s = readfromfile( ss )

    # initialize random numbers
    rngs = RandomNumberGenerators( nthreads() )

    @ensure isa( s.products, DataFrame )   "was expecting a DataFrame for product data"
    AddConstant!( s.products )
    MustBeInDF( [ v.market; v.product ], s.products, "products" )
    # **** TEST WHETHER THINGS MAKE SENSE; CAN'T HAVE INTERACTIONS AND NO MICRO DATA FOR INSTANCE
    
    markets = sort( unique( string.( s.products[:,v.market] ) ) )
    M = length( markets )

    mic = Vec{ GrumpsMicroData{T} }( undef, M )
    mac = Vec{ GrumpsMacroData{T} }( undef, M )
    fap = [ findall( x->x == markets[m], s.products[:, v.market ] ) for m ∈ 1:M ]


    dθν = length( v.randomcoefficients ) + dim( u, :randomcoefficients )
    dθ = dθν + size(v.interactions,1) + dim( u, :interactions )

    # ranges = SplitEqually( M, nthreads() )
    # process data needed for the micro likelihood
    println( "****************\n", e, "  ", usesmicrodata( e ),"\n*************" )
    @warnif !usesmicrodata( e ) && isa( s.consumers, DataFrame ) "ignoring consumer information since it is not used for this estimator type"
    @ensure !usesmicrodata( e ) || isa( s.consumers, DataFrame ) "this estimator type requires consumer information"

    @info "estimator = $e"
    if isa( s.consumers, DataFrame ) && usesmicrodata( e )
        MustBeInDF( [ v.market, v.choice ], s.consumers, "consumers" )
        nwgmic = NodesWeightsGlobal( microintegrator( integrators ), dθν, rngs[1]  )
        # @threads for th ∈ eachindex( ranges )
            # for m ∈ ranges[th]
            @threads :dynamic for m ∈ 1:M
                local th = threadid()
                local fac = findall( x->x == markets[m], s.consumers[:, v.market] )
                if fac ≠ nothing
                    local nw = NodesWeightsOneMarket( microintegrator( integrators ), dθν, rngs[ th ], nwgmic  )
                    mic[m] = GrumpsMicroData( markets[m], view( s.consumers, fac, : ), view( s.products, fap[m], : ), v, nw, rngs[th], options, usesmicromoments( e ), T, u )
                else
                    mic[m] = GrumpsMicroNoData( markets[m] )
                end
            end
        # end
    else
        for m ∈ 1:M
            mic[m] = GrumpsMicroNoData( markets[m] )
        end
    end

    # process data needed for the macro likelihood
    @warnif !usesmacrodata( e ) && isa( s.marketsizes, DataFrame ) "ignoring market size information since it is not used for this estimator type"
    @ensure !usesmacrodata( e ) || isa( s.marketsizes, DataFrame ) "this estimator type requires market size information"
    if isa( s.marketsizes, DataFrame ) && usesmacrodata( e )
        MustBeInDF( [ v.market, v.marketsize ], s.marketsizes, "market sizes" )
        nwgmac = NodesWeightsGlobal( macrointegrator( integrators ), dθ, s.draws, v, rngs[1] )
        # @threads for th ∈ eachindex( ranges )
            # for m ∈ ranges[th]
        @threads :dynamic for m ∈ 1:M
            local th = threadid()
                local fam = findfirst( x->x == markets[m], s.marketsizes[:, v.market] )
                if fam ≠ nothing
                    local draws = s.draws == nothing ? nothing : 
                        begin
                            local fad = findall( x-> x == markets[m], s.draws[:, v.market] )
                            @ensure fad ≠ nothing  "cannot find market $(markets[m])"
                            view( s.draws, fad, : )
                        end
                    local nw = NodesWeightsOneMarket( macrointegrator( integrators ), dθν, draws, v, rngs[ th ], nwgmac  )
                    mac[m] = GrumpsMacroData( markets[m], s.marketsizes[fam, v.marketsize], view( s.products, fap[m], : ), v, nw, isassigned( mic, m ) ? mic[m] : nothing, options, T, u )
                else
                    mac[m] = GrumpsMacroNoData{T}( markets[m] )
                end
            end
        # end
    else
        for m ∈ 1:M
            mac[m] = GrumpsMacroNoData{T}( markets[m] )
        end
    end


    # create product level data
    plm = GrumpsPLMData( s, v, fap, usespenalty( e ), T( options.σ2 ) )

    # now create variable labels
    marketproductstrings = vcat( [ [ ( c == 1 ) ? markets[m] : string( s.products[ fap[m][r], v.product ] ) for r ∈ 1:length( fap[m] ), c ∈ 1:2 ] for m ∈ 1:M ] ... )
    varnames = VariableNames( 
        v.interactions,                 # names of interaction variables
        v.randomcoefficients,           # names of random coefficients
        plm.names,                      # names of all regressor variables
        marketproductstrings,           # names of all market, product combinations
        u.interactionnames,             # names of all user-created interaction variables
        u.randomcoefficientnames )      # names of all user-created random coefficients
    
    nrm = Vec{ GrumpsNormalization{T} }(undef, dθ )
    dims = Dimensions( dθ, dθ - dθν, dθν, length( plm.names ), length.( fap ), dimmom( plm ) + size( v.microinstruments, 1 ) )
    gd = GrumpsData{T}( mic, mac, plm, varnames, nrm, dims )
    Balance!( gd, Val( options.balance ) )
    return gd
end

# GrumpsData( 
#     e                   :: Estimator,
#     x...
#     ) = GrumpsData( Version( e ), x... )


"""
    Data( 
        e                   :: GrumpsEstimator,
        ss                  :: Sources,
        v                   :: Variables,
        integrators            :: GrumpsIntegrators = BothIntegrators(),
        T                   :: Type = F64,
        u                   :: UserEnhancement = DefaultUserEnhancement();
        options             :: DataOptions = GrumpsDataOptions()
        )

Takes user inputs and converts them into an object that Grumps can understand.  This is synonymous with GrumpsData(...).

*Data* takes the following arguments, of which the first three are mandatory:

* *e*:                   estimator; see *Estimator*
* *ss*:                  cata sources; see *Sources*
* *v*:                   variables to be used; see *Variables*
* *integrators*:            see *BothIntegrators*, *DefaultMicroIntegrator*, and *DefaultMacroIntegrator*
* *T*:                   floating point type; not heavily tested
* *u*:                   not yet implemented
* *options*:             data options to be used, see *DataOptions*
"""
Data(x...) = GrumpsData(x...)
