push!( LOAD_PATH, "../src" )

using Grumps, LinearAlgebra

function myprogram( nodes, draws, meth  )
    s = Sources(                                                            
      consumers = "testdata/example_consumers.csv",
      products = "testdata/example_products.csv",
      marketsizes = "testdata/example_marketsizes.csv",
      draws = "testdata/example_draws.csv"  
    )
    v = Variables( 
        interactions =  [                                                   
            :income :constant; 
            :income :ibu; 
            :age :ibu
            ],
        randomcoefficients =  [:ibu; :abv],     
        regressors =  [ :constant; :ibu; :abv ],      
        instruments = [ :constant; :ibu; :abv; :IVgh_ibu; :IVgh_abv ], 
        microinstruments = [                                                
            :income :constant; 
            :income :ibu; 
            :age :ibu
            ],
        outsidegood = "product 11"                                          
    )
    
    e = Estimator( meth )                                                     

    d = Data( e, s, v; replicable = true ) 
    sol = grumps!( e, d )           
    return sol
end


sol = myprogram( 11, 10_000, "cheap" )
println( getθcoef( sol ) )
println( getδcoef( sol ) )
println( getβcoef( sol ) )
θ = getθ( sol )
β = getβ( sol )
δ = getδ( sol )


println( norm( gettstat.( θ ) ) )
println( norm( gettstat.( β ) ) )
println( norm( gettstat.( δ ) ) )


