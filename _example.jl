push!(LOAD_PATH, "src")
using Grumps, LinearAlgebra


BLAS.set_num_threads(8)

function myprogram( nodes, draws, meth  )
    @info "setting source files"
    s = Sources(
      consumers = "_example_consumers.csv",
      products = "_example_products.csv",
      marketsizes = "_example_marketsizes.csv",
      draws = "_example_draws.csv"  
    )
    # println( s )
    @info "setting variables"
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
    @info "setting data options"
    dop = DataOptions( ;micromode = :Hog, macromode = :Ant, balance = :micro )

    @info "setting integrators"
    ms = DefaultMicroIntegrator( nodes )
    Ms = DefaultMacroIntegrator( draws )
    @info "setting estimator"
    e = Estimator( meth )
    @info "processing data"
    d = Data( e, s, v, BothIntegrators( ms, Ms ) )
    @info "setting threads"
    th = Grumps.GrumpsThreads( ; markets = 36 )
    @info "setting optimization options"
    o = Grumps.OptimizationOptions(; memsave = true, threads = th )
    seo = StandardErrorOptions(; δ = true )
    @info "running grumps"
    grumps!( e, d, o, nothing, seo  )
    # @time grumps(e, d, OptimizationOptions(), nothing, Grumps.StandardErrorOptions() ) 
end

# for nodes ∈ [ 11 ] # , 17, 25]
#     for draws ∈ [10_000 ]  
#         for meth ∈ [ :gmm, :mixedlogit, :pml, :shareconstraint, :vanilla ]
#             @info "$nodes $draws $meth"
#             println( getcoef.( getθ( myprogram( nodes, draws, meth ) ) ) )
#         end
#     end
# end


const meth = length( ARGS ) > 0 ? Symbol( ARGS[1] ) : :pml

sol = myprogram( 11, 10_000, meth ) 
println( sol )

