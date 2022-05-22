

abstract type Variables end

struct GrumpsVariables <: Variables

    market              :: Symbol           # market data
    product             :: Symbol           # product data
    choice              :: Symbol           # choice data
    interactions        :: Mat{Symbol}      # micro interactions
    randomcoefficients  :: Vec{Symbol}      # micro random coefficients
    outsidegood         :: String           # outside good
    share               :: Symbol           # share data
    marketsize          :: Symbol           # market size
    regressors          :: Vec{Symbol}      # second stage regressors
    instruments         :: Vec{Symbol}      # second stage instruments
    dummies             :: Vec{Symbol}      # variables to be turned into dummy variables
    nuisancedummy       :: Symbol           # variable to be turned into a nuisance dummy
    microinstruments    :: Mat{Symbol}      # micro instruments (only for GMM)
    user                :: Mat{Symbol}      # user-specified inputs

    function GrumpsVariables( 
        market              :: Symbol, 
        product             :: Symbol, 
        choice              :: Symbol, 
        interactions        :: Mat{Symbol}, 
        randomcoefficients  :: Vec{Symbol},
        outsidegood         :: String, 
        share               :: Symbol, 
        marketsize          :: Symbol, 
        regressors          :: Vec{Symbol}, 
        instruments         :: Vec{Symbol}, 
        dummies             :: Vec{Symbol}, 
        nuisancedummy       :: Symbol, 
        microinstruments    :: Mat{Symbol},
        user                :: Mat{Symbol} 
        )

        @ensure length( regressors ) ≤ length( instruments )   "underidentified (#regressors > #increuments)"
        @ensure size( interactions, 1 ) ≥ 1   "need at least one interaction"
        new( market, product, choice, interactions, randomcoefficients, outsidegood, share, marketsize, regressors,      instruments, dummies, nuisancedummy, microinstruments, user )
    end
end


"""
    function Variables( ; 
      market              :: Symbol = :market,
      choice              :: Symbol = :choice,
      interactions        :: Mat{Symbol} = [],
      randomcoefficients  :: Vec{Symbol} = [],
      outsidegood         :: String = "outsidegood",
      share               :: Symbol = :share,
      marketsize          :: Symbol = :N,
      regressors          :: Vec{Symbol} = [],
      instruments         :: Vec{Symbol} = [],
      dummies             :: Vec{Symbol} = [],
      nuisancedummy       :: Symbol = :none,
      microinstruments    :: Mat{Symbol} = [],
      user                :: Mat{Symbol} = []
        )  

This method creates an object of type GrumpsVariables.  It contains references to the variables that Grumps uses to create variables from
the data sources specified by the call to the **Sources** function. 

For instance, *market* is the column heading in the source spreadsheets for the market indicator.  This get's passed as a symbol,
so the default (:market) says that the column heading is *market*, which is both case and spaces sensititve.  The same column heading 
is used across all sources.  All entries with the exception of *outsidegood* refer to the column heading: *outsidegood* refers to the
label used for the outside good, which should be the same across both spreadsheets and markets.


*market* refers to the variable containing the market indicator in all input datasets

*product* refers to the variable containing the product indicator in the product dataset

*choice* refers to the variable indicating the choice indicator in the consumer level datasets

*interactions* refers to the variables indicating consumer and product variable interactions (each row contains consumer variable, product variable)

*randomcoefficients* refers to the product level variables that have a random coefficient on them

*outsidegood* refers to the label used for the outside good

*share* refers to the label used for the product level share

*marketsize* refers to the size of the market (number of people)

*regressors* refers to the label used for the second stage regressors

*instruments* refers to the label used for the second stage instruments

*dummies* refers to discrete variables to be converted to second stage dummy regressors and instruments

*nuisancedummy* refers to at most one variable to be converted to a second stage dummy regressors and instrument whose coefficient value is of no interest

*microinstruments* refers to micro instruments, which are only relevant for gmm style procedures

*user* refers to a list of variables to be added to the consumer-product interactions using a user-specified procedure
"""
function Variables( ; 
    market              :: Symbol = :market,
    product             :: Symbol = :product,
    choice              :: Symbol = :choice,
    interactions        = Mat{Symbol}(undef, 0, 0),
    randomcoefficients  = Vec{Symbol}(undef, 0),
    outsidegood         :: String = "outsidegood",
    share               :: Symbol = :share,
    marketsize          :: Symbol = :N,
    regressors          = Vec{Symbol}(undef,0),
    instruments         = Vec{Symbol}(undef,0),
    dummies             = Vec{Symbol}(undef,0),
    nuisancedummy       :: Symbol = :none,
    microinstruments    = Mat{Symbol}(undef, 0,0),
    user                = Mat{Symbol}(undef, 0, 0 )
      )
    
    GrumpsVariables( market, product, choice, interactions, randomcoefficients, outsidegood, share, marketsize, regressors, instruments, dummies, nuisancedummy, microinstruments, user )
end



function show( io :: IO, v :: Variables; adorned = true )
    prstyledln( adorned, "column headings used:"; color = :blue, bold = true )
    for fld ∈ [ :market, :product, :choice, :share, :marketsize ]
          prstyled( adorned, @sprintf( "%30s: ", fld); bold = true );  println( getfield( v, fld ) )
      end
    prstyledln( adorned, "labels used:"; color = :blue, bold = true )
    for fld ∈ [ :outsidegood ]
      prstyled( adorned, @sprintf( "%30s: ", fld); bold = true );  println( getfield( v, fld ) )
    end
    prstyledln( adorned, "interactions used:"; color = :blue, bold = true )
    if size( v.interactions, 1 ) == 0
        prstyledln( adorned, @sprintf("%30s", "none" ); underline = true )
    else
        for r ∈ axes( v.interactions, 1 )
            println( @sprintf( "%30s * ", v.interactions[r,1] ), v.interactions[r,2] ) 
        end
    end
    for fn ∈ [ :regressors, :instruments, :dummies, :nuisancedummy ]
        prstyledln( adorned, "$fn:"; color = :blue, bold = true )
        el = getfield( v, fn )
        if typeof( el ) <: Vector
            if length( el ) == 0
                @printf("%26s", ""); prstyledln( adorned, "none" ; underline = true  )
            else
                for r ∈ eachindex( el )
                    println( @sprintf( "%30s", el[r] ) )
                end
            end
        else
            println( @sprintf("%30s", el ) )
        end
    end
    prstyledln( adorned, "micro instruments used:"; color = :blue, bold = true )
    if size( v.microinstruments, 1 ) == 0
        prstyledln( adorned, @sprintf("%30s", "none" ); underline = true )
    else
        for r ∈ axes( v.microinstruments, 1 )
            println( @sprintf( "%30s * ", v.microinstruments[r,1] ), v.microinstruments[r,2] ) 
        end
    end

    @warn "finish show(io, v::Variables)"
end



function show( io :: IO, mime ::MIME{Symbol("text/plain")}, v :: Variables )
    show( io :: IO, v :: Variables; adorned = false )
end