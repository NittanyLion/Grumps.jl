push!(LOAD_PATH, ".")
using Grumps

Grumps.@Imports()



function mle(  )
    @info "setting source files"
    s = Sources(
      consumers = "_ss_consumers.csv",
      products = "_ss_products.csv",
      marketsizes = "_ss_marketsizes.csv",
      draws = "_ss_draws.csv"  
    )
    println( s )
    v = Variables(
        interactions =  [
            :income :constant; 
            :income :ibu; 
            :age :ibu
            ],
        randomcoefficients =  [:ibu; :abv],
        # regressors =  [ :constant; :ibu; :abv ],
        regressors =  [ :constant; :ibu; :abv ],
        instruments = [ :constant; :ibu; :abv; :IVgh_ibu; :IVgh_abv ],
        microinstruments = [
            :income :constant; 
            :income :ibu; 
            :age :ibu
            ],
        outsidegood = "outside"
    )
    println( v )
    dop = DataOptions( ;micromode = :Hog, macromode = :Ant, balance = :micro )
    e = Estimator( "gmm" )
    d = Data( e, s, v )
    # th = Grumps.GrumpsThreads(; markets = 1, inner = 1 )
    # grumps( e, d )

    grumps(e, d, OptimizationOptions(), nothing, Grumps.StandardErrorOptions() ) 
end

mle()

