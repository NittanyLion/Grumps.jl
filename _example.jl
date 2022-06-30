push!(LOAD_PATH, "src")
using Grumps, LinearAlgebra

Grumps.@Imports()

BLAS.set_num_threads(8)

function myprogram( nodes, draws  )
    @info "setting source files"
    s = Sources(
      consumers = "_example_consumers.csv",
      products = "_example_products.csv",
      marketsizes = "_example_marketsizes.csv",
      draws = "_example_draws.csv"  
    )
    # println( s )
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
        outsidegood = "product 11"
    )
    # println( v )
    dop = DataOptions( ;micromode = :Hog, macromode = :Ant, balance = :micro )

    ms = DefaultMicroIntegrator( nodes )
    Ms = DefaultMacroIntegrator( draws )
    e = Estimator( "pml" )
    d = Data( e, s, v, BothIntegrators( ms, Ms ) )
    th = Grumps.GrumpsThreads( ; markets = 4 )
    o = Grumps.OptimizationOptions(; memsave = true, threads = th )
    grumps( e, d, o  )
    # @time grumps(e, d, OptimizationOptions(), nothing, Grumps.StandardErrorOptions() ) 
end

for nodes ∈ [ 11 ] # , 17, 25]
    for draws ∈ [10_000 ]  
        @info "$nodes $draws"
        println( getcoef.( getθ( myprogram( nodes, draws ) ) ) )
    end
end



