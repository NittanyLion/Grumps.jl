# The functions below take user inputs and create Grumps data objects.
# Each of these functions then calls separate routines to process micro likelihood
# data, macro likelihood data, and product level moments data.


"""
    GrumpsData( 
        e                   :: GrumpsEstimator,
        ss                  :: Sources,
        v                   :: Variables,
        integrators         :: GrumpsIntegrators = BothIntegrators(),
        T                   :: Type = F64,
        options             :: DataOptions = GrumpsDataOptions(),
        threads             :: Int = 0,
        id                  :: Symbol = :default
        )

Takes user inputs and converts them into an object that Grumps can understand.  This is synonymous with Data(...).

*GrumpsData* takes the following arguments, of which the first three are mandatory:

* *e*:                   estimator; see *Estimator*
* *ss*:                  cata sources; see *Sources*
* *v*:                   variables to be used; see *Variables*
* *integrators*:         see *BothIntegrators*, *DefaultMicroIntegrator*, and *DefaultMacroIntegrator*
* *T*:                   floating point type; not heavily tested
* *options*:             data options to be used, see *DataOptions*
* *threads*:             the number of parallel threads to be used in creating data
* *id*:                  an id that can be used to define user-specific versions
"""
function GrumpsData( 
    e                   :: GrumpsEstimator,
    ss                  :: Sources,
    v                   :: Variables,
    integrators         :: GrumpsIntegrators = BothIntegrators(),
    T                   :: Type = F64;
    options             :: DataOptions = GrumpsDataOptions(),
    threads             :: Int = 0,
    id                  :: Symbol = :default
    )

    # check compatibility of choices made 
    CheckCompatible( e, integrators, options )
    
    # read data from file if not already done
    @info "reading data"
    s = readfromfile( ss )

    # initialize random numbers
    @info "creating random number generators"
    if threads ≤ 0 
        threads = nthreads()
    end
    threads = min( nthreads(), threads )
    rngs = RandomNumberGenerators( nthreads() )

    @ensure isa( s.products, DataFrame )   "was expecting a DataFrame for product data"
    AddConstant!( s.products )
    MustBeInDF( [ v.market; v.product ], s.products, "products" )
    
    markets = sort( unique( string.( s.products[:,v.market] ) ) )
    M = length( markets )

    mic = Vec{ GrumpsMicroData{T} }( undef, M )
    mac = Vec{ GrumpsMacroData{T} }( undef, M )
    fap = [ findall( x->string(x) == markets[m], s.products[:, v.market ] ) for m ∈ 1:M ]


    dθν = length( v.randomcoefficients )# + dim( u, :randomcoefficients )
    dθ = dθν + size(v.interactions,1)# + dim( u, :interactions )

    # process data needed for the micro likelihood
    @warnif !usesmicrodata( e ) && isa( s.consumers, DataFrame ) "ignoring the consumer information you specified since it is not used for this estimator type"
    @ensure !usesmicrodata( e ) || isa( s.consumers, DataFrame ) "this estimator type requires consumer information; please pass consumer info in Sources"
    sema = Semaphore( threads )

    @info "creating data objects for micro likelihood"
    if isa( s.consumers, DataFrame ) && usesmicrodata( e )
        MustBeInDF( [ v.market, v.choice ], s.consumers, "consumers" )
        nwgmic = NodesWeightsGlobal( microintegrator( integrators ), dθν, rngs[1]  )
        @threads for m ∈ 1:M
            acquire( sema )
            local th = threads == 1 ? 1 : threadid()
            local fac = findall( x->string(x) == markets[m], s.consumers[:, v.market] )
            if fac ≠ nothing
                local nw = NodesWeightsOneMarket( microintegrator( integrators ), dθν, rngs[ th ], nwgmic, length( fac )  )
                # check that all products in the consumer data set are also in the products data set
                mic[m] = GrumpsMicroData( Val( id ), markets[m], view( s.consumers, fac, : ), view( s.products, fap[m], : ), v, nw, rngs[th], options, usesmicromoments( e ), T )
            else
                mic[m] = GrumpsMicroNoData( markets[m] )
            end
            release( sema )
        end
    else
        for m ∈ 1:M
            mic[m] = GrumpsMicroNoData( markets[m] )
        end
    end

    # process data needed for the macro likelihood
    @info "creating data objects for macro likelihood"
    @warnif !usesmacrodata( e ) && isa( s.marketsizes, DataFrame ) "ignoring the market size information you provided since it is not used for this estimator type"
    @ensure !usesmacrodata( e ) || isa( s.marketsizes, DataFrame ) "this estimator type requires market size information; please pass market size information in Sources"
    if isa( s.marketsizes, DataFrame ) && usesmacrodata( e )
        MustBeInDF( [ v.market, v.marketsize ], s.marketsizes, "market sizes" )
        nwgmac = NodesWeightsGlobal( macrointegrator( integrators ), dθ, s.draws, v, rngs[1] )
        subdfs = groupby( s.draws, v.market )
        marketsdrawn = [ subdfs[m][1,v.market] for m ∈ eachindex( subdfs ) ]
        @threads for m ∈ 1:M
            acquire( sema )
            local th = threads == 1 ? 1 : threadid()
            local fama = findall( x->string(x) == markets[m], s.marketsizes[:, v.market] )
            if fama ≠ nothing
                @warnif length( fama ) > 1 "multiple lines in the market sizes data with the same market name; using the first one"
                fam = fama[1]
                local 𝒾 = findfirst( x->string( x ) == markets[m], marketsdrawn )
                local nw = NodesWeightsOneMarket( macrointegrator( integrators ), dθν, 𝒾 == nothing ? nothing : subdfs[𝒾], v, rngs[ th ], nwgmac  )
                mac[m] = GrumpsMacroData( Val( id ), markets[m], s.marketsizes[fam[1], v.marketsize], view( s.products, fap[m], : ), v, nw, isassigned( mic, m ) ? mic[m] : nothing, options, T )
            else
                mac[m] = GrumpsMacroNoData{T}( markets[m] )
            end
            release( sema )
        end
    else
        for m ∈ 1:M
            mac[m] = GrumpsMacroNoData{T}( markets[m] )
        end
    end

    @info "creating objects for use in product level moments term"
    # create product level data
    plm = GrumpsPLMData( Val( id ), e, s, v, fap, usespenalty( e ), T( options.σ2 ) )

    # now create variable labels
    marketproductstrings = vcat( [ [ ( c == 1 ) ? markets[m] : string( s.products[ fap[m][r], v.product ] ) for r ∈ 1:length( fap[m] ), c ∈ 1:2 ] for m ∈ 1:M ] ... )
        
    varnames = VariableNames( 
        v.interactions,                 # names of interaction variables
        v.randomcoefficients,           # names of random coefficients
        plm.names,                      # names of all regressor variables
        marketproductstrings            # names of all market, product combinations
        # Vector{[],
        # []
        # u.interactionnames,             # names of all user-created interaction variables
        # u.randomcoefficientnames )      # names of all user-created random coefficients
    )
    
    nrm = Vec{ GrumpsNormalization{T} }(undef, dθ )
    dims = Dimensions( dθ, dθ - dθν, dθν, length( plm.names ), length.( fap ), dimmom( plm ) + (( typeof(e) <: GrumpsGMM) ? size( v.microinstruments, 1 ) : 0 ) )
    @info "creating data objects"
    gd = GrumpsData{T}( mic, mac, plm, varnames, nrm, dims )
    @info "balancing"
    Balance!( gd, Val( options.balance ) )
    return gd
end



"""
    Data( 
        e                   :: GrumpsEstimator,
        ss                  :: Sources,
        v                   :: Variables,
        integrators         :: GrumpsIntegrators = BothIntegrators(),
        T                   :: Type = F64,
        u                   :: UserEnhancement = DefaultUserEnhancement();
        options             :: DataOptions = GrumpsDataOptions(),
        threads             :: Int = 0
        )

Takes user inputs and converts them into an object that Grumps can understand.  This is synonymous with GrumpsData(...).

*Data* takes the following arguments, of which the first three are mandatory:

* *e*:                   estimator; see *Estimator*
* *ss*:                  cata sources; see *Sources*
* *v*:                   variables to be used; see *Variables*
* *o*:                   optimization options to be used   
* *integrators*:         see *BothIntegrators*, *DefaultMicroIntegrator*, and *DefaultMacroIntegrator*
* *T*:                   floating point type; not heavily tested
* *u*:                   not yet implemented
* *options*:             data options to be used, see *DataOptions*
* *threads*:             the number of parallel threads to be used in creating data
"""
Data(x...; y...) = GrumpsData(x...; y... )
