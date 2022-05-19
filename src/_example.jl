push!(LOAD_PATH, ".")
using Grumps

Grumps.@Imports()



function mle(  )
    @info "setting source files"
    s = Sources(
      consumers = "_example_consumers.csv",
      products = "_example_products.csv",
      marketsizes = "_example_marketsizes.csv",
      draws = "_example_draws.csv"  
    )
    println( s )
    v = Variables(
        interactions =  [
            :income :constant; 
            :income :ibu; 
            :age :ibu
            ],
        randomcoefficients =  [:ibu; :abv],
        regressors =  [ :constant; :ibu; :abv ],
        instruments = [ :constant; :ibu; :abv; :IVgh_ibu; :IVgh_abv ],
        outsidegood = "product 11"
    )
    println( v )
    dop = DataOptions( ;micromode = :Hog, macromode = :Ant, balance = :micro )
    e = Estimator( "gmm" )
    d = Data( e, s, v )
    # th = Grumps.GrumpsThreads(; markets = 1, inner = 1 )
    # grumps( e, d )

    grumps(e, d, OptimizationOptions(), fill(0.5,5), Grumps.StandardErrorOptions() ) 
end

mle()

