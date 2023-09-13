# The functions below take user inputs and create Grumps data objects.
# Each of these functions then calls separate routines to process micro likelihood
# data, macro likelihood data, and product level moments data.



function MicroCreation!( replicable, markets, s, v, integrators, dθν, rngs, nwgmic, mic, id, fap, options, e, T :: Type{ 𝒯 }, m ) where 𝒯
    th = replicable ? 1 : m
    fac = findall( x->string(x) == markets[m], s.consumers[:, v.market] ) :: Vector{ Int }
    if length( fac ) > 0
        nw = NodesWeightsOneMarket( microintegrator( integrators ), dθν, rngs[ th ], nwgmic, length( fac )  )
        # check that all products in the consumer data set are also in the products data set
        mic[m] = GrumpsMicroData( id, markets[m], view( s.consumers, fac, : ), view( s.products, fap[m], : ), v, nw, rngs[th], options, usesmicromoments( e ), m, T )
    else
        mic[m] = GrumpsMicroNoData( markets[m] )
    end
end

function MacroCreation!( replicable, markets, s, v, marketsdrawn, integrators, dθν, subdfs, rngs, nwgmac, id, fap, mic, mac, T :: Type{ 𝒯 }, options, m ) where 𝒯
    th = replicable ? 1 : m
    fama = findall( x->string(x) == markets[m], s.marketsizes[:, v.market] ) :: Vector{ Int }
    if length( fama ) > 0
        @warnif length( fama ) > 1 "multiple lines in the market sizes data with the same market name; using the first one"
        fam = fama[1]
        𝒾 = findfirst( x->string( x ) == markets[m], marketsdrawn )
        nw = NodesWeightsOneMarket( macrointegrator( integrators ), dθν, 𝒾 == nothing ? nothing : subdfs[𝒾], v, rngs[ th ], nwgmac  )
        mac[m] = GrumpsMacroData( Val( id ), markets[m], T( s.marketsizes[fam[1], v.marketsize] ) :: T, view( s.products, fap[m], : ), v, nw, isassigned( mic, m ) ? mic[m] : nothing, options, T )
    else
        @warn "no macro data for $(markets[m])"
        mac[m] = GrumpsMacroNoData{T}( markets[m] )
    end
end


function GrumpsData( 
    id                  :: Any,
    e                   :: GrumpsEstimator,
    ss                  :: Sources,
    v                   :: Variables,
    integrators         :: GrumpsIntegrators = BothIntegrators(),
    T                   :: Type{ 𝒯 } = F64;
    options             :: DataOptions = GrumpsDataOptions(),
    replicable          :: Bool = true
    ) where 𝒯


    # check compatibility of choices made 
    CheckCompatible( e, integrators, options )

    replicable :: Bool = CheckInteractionsCallBackFunctionality( replicable, options, T )

    # read data from file if not already done
    s = readfromfile( ss )



    @ensure isa( s.products, DataFrame )   "was expecting a DataFrame for product data"
    AddConstant!( s.products )
    MustBeInDF( [ v.market; v.product ], s.products, "products" )
    
    markets = sort(  unique( String.( string.( s.products[:,v.market] ) ) :: Vector{String} ) ) :: Vector{String}
    M = length( markets )

    # replicable || advisory( "replicability is set to false\nthis is faster\nbut you will get different results\nfrom one run to the next" )
    # replicable && advisory( "replicability is set to true\nthis is slower\nbut you will get the same results\nfrom one run to the next" )
    rngs = RandomNumberGenerators( M; replicable = replicable )

    mic = Vec{ GrumpsMicroData{T} }( undef, M )
    mac = Vec{ GrumpsMacroData{T} }( undef, M )
    fap = [ findall( x->string(x) == markets[m], s.products[:, v.market ] ) :: Vector{Int} for m ∈ 1:M ]

    dθν = length( v.randomcoefficients )
    dθ = dθν + size(v.interactions,1)

    # process data needed for the micro likelihood
    !usesmicrodata( e ) && isa( s.consumers, DataFrame ) && advisory( "ignoring the consumer information you specified\nsince it is not used for this estimator type" )
    @ensure !usesmicrodata( e ) || isa( s.consumers, DataFrame ) "this estimator type requires consumer information; please pass consumer info in Sources"

    if isa( s.consumers, DataFrame ) && usesmicrodata( e )
        MustBeInDF( [ v.market, v.choice ], s.consumers, "consumers" )
        nwgmic = NodesWeightsGlobal( microintegrator( integrators ), dθν, rngs[1]  )
        if replicable 
            for m ∈ 1:M
                MicroCreation!( replicable, markets, s, v, integrators, dθν, rngs, nwgmic, mic, id, fap, options, e, T, m )
            end
        else
            @threads for m ∈ 1:M
                MicroCreation!( replicable, markets, s, v, integrators, dθν, rngs, nwgmic, mic, id, fap, options, e, T, m )
            end
        end
    else
        for m ∈ 1:M
            mic[m] = GrumpsMicroNoData( markets[m] )
        end
    end

    # process data needed for the macro likelihood
    !usesmacrodata( e ) && isa( s.marketsizes, DataFrame ) && advisory( "ignoring the market size information you provided\nsince it is not used for this estimator type" )
    @ensure !usesmacrodata( e ) || isa( s.marketsizes, DataFrame ) "this estimator type requires market size information; please pass market size information in Sources"
    if isa( s.marketsizes, DataFrame ) && usesmacrodata( e )
        MustBeInDF( [ v.market, v.marketsize ], s.marketsizes, "market sizes" )
        nwgmac = NodesWeightsGlobal( macrointegrator( integrators ), dθ, s.draws, v, rngs[1] )
        subdfs = groupby( s.draws, v.market )
        marketsdrawn = [ subdfs[m][1,v.market] for m ∈ eachindex( subdfs ) ]

        if replicable
            for m ∈ 1:M
                MacroCreation!( replicable, markets, s, v, marketsdrawn, integrators, dθν, subdfs, rngs, nwgmac, id, fap, mic, mac, T, options, m )
            end
        else
            @threads for m ∈ 1:M 
                MacroCreation!( replicable, markets, s, v, marketsdrawn, integrators, dθν, subdfs, rngs, nwgmac, id, fap, mic, mac, T, options, m )
            end
        end
    else
        for m ∈ 1:M
            mac[m] = GrumpsMacroNoData{T}( markets[m] )
            @ensure typeof( mic[m] ) ≠ GrumpsMicroNoData{T} "neither micro data nor macro data in market $(s.products[fap[m][1],v.market])"
        end
    end

    # create product level data
    template = Template( Val( id ), options, s.products, fap )
    plm = GrumpsPLMData( Val( id ), e, s, v, fap, usespenalty( e ), VarianceMatrixξ( options ), template )

    # now create variable labels
    marketproductstrings = vcat( [ [ ( c == 1 ) ? markets[m] : string( s.products[ fap[m][r], v.product ] ) for r ∈ 1:length( fap[m] ), c ∈ 1:2 ] for m ∈ 1:M ] ... )
        
    varnames = VariableNames( 
        v.interactions,                 # names of interaction variables
        v.randomcoefficients,           # names of random coefficients
        plm.names,                      # names of all regressor variables
        v.instruments,                  # names of all instruments
        marketproductstrings            # names of all market, product combinations
    )
    
    nrm = Vec{ GrumpsNormalization{T} }(undef, dθ )
    dims = Dimensions( dθ, dθ - dθν, dθν, length( plm.names ), length.( fap ), dimmom( plm ) + (( typeof(e) <: GrumpsGMM) ? size( v.microinstruments, 1 ) : 0 ) )

    gd = GrumpsData{T}( mic, mac, plm, varnames, nrm, dims )
    Balance!( gd, Val( options.balance ) )


    return gd
end

"""
    GrumpsData( 
        e                   :: GrumpsEstimator,
        ss                  :: Sources,
        v                   :: Variables,
        integrators         :: GrumpsIntegrators = BothIntegrators(),
        T                   :: Type = F64,
        options             :: DataOptions = GrumpsDataOptions(),
        replicable          :: Bool = true
        )

Takes user inputs and converts them into an object that Grumps can understand.  This is synonymous with Data(...).

*GrumpsData* takes the following arguments, of which the first three are mandatory:

* *e*:                   estimator; see *Estimator*
* *ss*:                  cata sources; see *Sources*
* *v*:                   variables to be used; see *Variables*
* *integrators*:         see *BothIntegrators*, *DefaultMicroIntegrator*, and *DefaultMacroIntegrator*
* *T*:                   floating point type; not heavily tested
* *options*:             data options to be used, see *DataOptions*
* *replicable*:          whether results must be replicable (slows down speed of data creation if set to true)
"""
function GrumpsData( 
    e                   :: GrumpsEstimator,
    ss                  :: Sources,
    v                   :: Variables,
    integrators         :: GrumpsIntegrators,
    T                   :: Type{𝒯} = F64;
    options             :: DataOptions = GrumpsDataOptions(),
    replicable          :: Bool = true
    )  where 𝒯
    
    return GrumpsData( Val( id( options ) ), e, ss, v, integrators, T; options = options, replicable = replicable )
end 

"""
    GrumpsData( 
        e                   :: GrumpsEstimator,
        ss                  :: Sources,
        v                   :: Variables,
        microintegrator     :: MicroIntegrator = DefaultMicroIntegrator(),
        microintegrator     :: MacroIntegrator = DefaultMacroIntegrator(),
        T                   :: Type = F64,
        options             :: DataOptions = GrumpsDataOptions(),
        replicable          :: Bool = true
        )

Takes user inputs and converts them into an object that Grumps can understand.  This is synonymous with GrumpsData(...).

*Data* takes the following arguments, of which the first three are mandatory:

* *e*:                   estimator; see *Estimator*
* *ss*:                  cata sources; see *Sources*
* *v*:                   variables to be used; see *Variables*
* *o*:                   optimization options to be used   
* *microintegrator*:     micro integrator see [Choice of integration method (integrators)](@ref)
* *macrointegrator*:     macro integrator see [Choice of integration method (integrators)](@ref)
* *T*:                   floating point type; not heavily tested
* *u*:                   not yet implemented
* *options*:             data options to be used, see *DataOptions*
* *replicable*:          whether results must be replicable (slows down speed of data creation if set to true)
"""
function GrumpsData( 
    e                   :: GrumpsEstimator,
    ss                  :: Sources,
    v                   :: Variables,
    microintegrator     :: MicroIntegrator = DefaultMicroIntegrator(),
    macrointegrator     :: MacroIntegrator = DefaultMacroIntegrator(),
    T                   :: Type{𝒯} = F64;
    options             :: DataOptions = GrumpsDataOptions(),
    replicable          :: Bool = true
    ) where 𝒯
    
    return GrumpsData( e, ss, v, BothIntegrators( microintegrator, macrointegrator ), T; options = options, replicable = replicable )
end


"""
    Data( 
        e                   :: GrumpsEstimator,
        ss                  :: Sources,
        v                   :: Variables,
        microintegrator     :: MicroIntegrator = DefaultMicroIntegrator(),
        macrointegrator     :: MacroIntegrator = DefaultMacroIntegrator(),
        T                   :: Type = F64,
        options             :: DataOptions = GrumpsDataOptions(),
        replicable          :: Bool = true
        )

Takes user inputs and converts them into an object that Grumps can understand.  This is synonymous with GrumpsData(...).

*Data* takes the following arguments, of which the first three are mandatory:

* *e*:                   estimator; see [Estimator choice](@ref)
* *ss*:                  data sources; see [Data entry](@ref)
* *v*:                   variables to be used; see [Data entry](@ref)
* *o*:                   optimization options to be used   
* *microintegrator*:     micro integrator see [Choice of integration method (integrators)](@ref)
* *macrointegrator*:     macro integrator see [Choice of integration method (integrators)](@ref)
* *T*:                   floating point type; not heavily tested
* *u*:                   not yet implemented
* *options*:             data options to be used, see [Data storage options](@ref)
* *replicable*:          whether results must be replicable (slows down speed of data creation if set to true)
"""
Data( x...; y... ) = GrumpsData( x...; y... )

# function Data( 
#     e                   :: GrumpsEstimator,
#     ss                  :: Sources,
#     v                   :: Variables,
#     microintegrator     :: MicroIntegrator = DefaultMicroIntegrator(),
#     macrointegrator     :: MacroIntegrator = DefaultMacroIntegrator(),
#     T                   :: Type = F64;
#     options             :: DataOptions = GrumpsDataOptions(),
#     replicable          :: Bool = false
#      )

#     return GrumpsData( e, ss, v, microintegrator, macrointegrator, T; options = options, replicable = replicable )

# end

