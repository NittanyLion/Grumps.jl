### Quick Start Guide

To use **Grumps.jl** consider the following program, which computes the unpenalized maximum likelihood estimator of Grieco, Murry, Pinkse, and Sagl.


    using Grumps, LinearAlgebra

    Grumps.@Imports()

    BLAS.set_num_threads(8)

    function myprogram(  )

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
            outsidegood = "outside"
        )
        println( v )

        e = Estimator( "pml" )

        d = Data( e, s, v )

         sol = grumps( e, d )

         println( sol )
    end

    myprogram()



To see what is happening in the code, note the following commands.  **Grumps.@Imports()** simply imports some common Grumps commands into your namespace.  It is not necessary; without it you would simply have to type e.g. Grumps.Variables instead of Variables.

Now consider the function myprogram.  It first describes where data on consumers, products, market sizes, and random draws can be found.  This happens in the **Sources** call. In this example, all sources are files, but DataFrames are ok, also.  In addition, not all sources are needed for all estimators and options.  Indeed, only products data are required.

Next, in **Variables** it describes what variables to include.  In this case, there are three interactions between demographic characteristics (in the first column) and product characteristics (in the second column).  There are moreover random coefficients on the ibu and abv variables.  The product-level regressors and instruments that go into $\hat \Pi$ are also entered.  Finally, the outsidegood argument indicates which value in the consumers spreadsheet is used to indicate that a product is the outside good.  ***should enter other variables, like product and market***

It then tells Grumps that it wants to use the full Grumps maximum likelihood estimator with penalized deviations from the macro moments in **Estimator**.  You could also have entered another descriptive string; **Grumps** is pretty good at figuring out what you want.  Or you can use a symbol, like :mle.  In the **Data** call, it reads the data needed from the sources indicated in the **Sources** call using the information specified in the **Variables** call.

The **grumps** call then asks Grumps to compute the estimates.

Note that there are many other options and calls.  The main ones are described in the **Objects** tab.

To get help on a command, simply load Grumps in the REPL and type e.g.
```
julia> ?Variables
```