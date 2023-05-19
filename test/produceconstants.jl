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

open( "constants",  "w") do fl
    write( fl, "resultsdict = Dict()")
    for meth ∈ [ :cler, :cheap, :mdle, :shareconstraint ]
        println( "meth = $meth")
        sol = myprogram( 11, 10_000, "$meth" )
        println( "computed $meth ", typeof( sol ) )
        write(fl, "resultsdict[ \"θsol$meth\" ] = $(getθcoef( sol ))\n" )
        write(fl, "resultsdict[ \"βsol$meth\" ] = $(getβcoef( sol ))\n" )
        write(fl, "resultsdict[ \"δsol$meth\" ] = $(getδcoef( sol ))\n" )
        θ = getθ( sol ) 
        β = getβ( sol )
        δ = getδ( sol )
        if meth ≠ :shareconstraint
            write(fl, "resultsdict[ \"θtstat$meth\" ] = $(norm(gettstat.( θ )))\n\n" )
            write(fl, "resultsdict[ \"βtstat$meth\" ] = $(norm(gettstat.( β )))\n\n" )
            write(fl, "resultsdict[ \"δtstat$meth\" ] = $(norm(gettstat.( δ )))\n\n" )
        end
        flush( fl )
    end
end


