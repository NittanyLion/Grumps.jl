

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

        @ensure length( regressors ) ≤ length( instruments )   "underidentified (#regressors > #increments)"
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

This method is used to specify regressors, instruments, random coefficients, interactions, etcetera, variable labels, etcetera, from
the sources you have specified in [`Sources()`](@ref). It creates an object of type *GrumpsVariables*.

For instance, the option *market* specifies the column heading of the column containing the market descriptor (name).  The same is true
for all other arguments, except *outsidegood* which describes the spreadsheet entry that indicates the product is an outside good.  The 
same label for the outside good should be used in all spreadsheets and all markets. Outside good entries 
should only be used in the consumer micro data and then only if there actually are consumers in the micro data choosing the outside good.
All descriptors are case and space sensitive.

There is a separation between variables that go into the individual consumer utility and ones that only go into "mean utility".  For instance,
*interactions* tells Grumps which interaction terms to use and *randomcoefficients* which product level regressors are hit with a random
coefficient.  By contrast, *regressors* go into the mean utility component and are regressors in the "second stage" (where β is recovered).
One can use the special symbol *:constant* to indicate a constant is to be used; the spreadsheet need not include a column with that heading.

Note that there are three ways that dummy variables can be entered as second stage regressors.  The first is via *regressors*, in which case
the onus is on the user to ensure that they have the correct numerical values.  The second possibility is via the *dummies* argument.  For 
each symbol passed via the *dummies* argument, Grumps will examine the corresponding column of the product data set (which can contain descriptive
entries that need not be numerical) and turn it into dummy variables.  If the coefficient on the dummies is of no interest then it is better to
pass one via the *nuisancedummy* argument since it saves both computation time and memory.  There can only be at most one categorical variable that can
be converted to nuisance dummies, but there can be arbitrarily many categories.  These dummies and nuisance dummies are automatically assumed to be
exogenous and will be included in the instruments, also.

*market* refers to the variable containing the market indicator in all input datasets.  Strings work best for the market indicators themselves,
but it is not a requirement.

*product* refers to the variable containing the product indicator in the product dataset. Strings work best for the product indicators themselves,
but it is not a requirement.

*choice* refers to the variable indicating the choice indicator in the consumer level datasets.  Strings work best for the choice indicators themselves,
but it is not a requirement.

*interactions* refers to the variables indicating consumer and product variable interactions (each row contains consumer variable, product variable)

*randomcoefficients* refers to the product level variables that have a random coefficient on them

*outsidegood* refers to the label used for the outside good

*share* refers to the label used for the product level share; these are shares where the denominator includes the outside good

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