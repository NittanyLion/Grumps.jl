### Quick Start Guide

To use **Grumps.jl** consider the following program, which computes the penalized maximum likelihood estimator of Grieco, Murry, Pinkse, and Sagl.


    using Grumps



    function myprogram(  )

        @info "setting source files"
        s = Sources(
            consumers = "example_consumers.csv",
            products = "example_products.csv",
            marketsizes = "example_marketsizes.csv",
            draws = "example_draws.csv"  
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

        sol = grumps!( e, d )

        println( sol )

        Save( "myresults.csv", sol )
    end

    myprogram()



To see what is happening in the code, consider the function myprogram.  It first describes where data on consumers, products, market sizes, and random draws can be found.  This happens in the `Sources` call. In this example, all sources are files, but DataFrames are ok, also.  In addition, not all sources are needed for all estimators and options.  Indeed, only products data are required.  See [Spreadsheet formats](@ref) for documentation on the spreadsheet formats.

Next, in `Variables` it describes what variables to include. There are two different but equivalent versions of this method: the only difference is the syntax to accommodate users' preferences.  The example here covers only one version. In this case, there are three interactions between demographic characteristics (in the first column) and product characteristics (in the second column).  There are moreover random coefficients on the ibu and abv variables.  The product-level regressors and instruments that go into $\hat \Pi$ are also entered.  Finally, the outsidegood argument indicates which value in the consumers spreadsheet is used to indicate that a product is the outside good.  There are many other choices; please see the User Interface section.

!!! tip "Objects can be printed"
    Most variables with data types created by Grumps can be printed.  For instance, the `println( v )` line tells Grumps to print the variable `v`, which in this case contains information about the specification. `println( d )` works too after the `Data` call.

It then tells Grumps that it wants to use the full Grumps maximum likelihood estimator with penalized deviations from the macro moments in `Estimator`.  You could also have entered another descriptive string; **Grumps** is pretty good at figuring out what you want.  Or you can use a symbol, like :mle.  In the `Data` call, it reads the data needed from the sources indicated in the `Sources` call using the information specified in the `Variables` call.

The `grumps!` call then asks Grumps to compute the estimates.  The exclamation mark (`bang`) signifies that `grumps!` can change its arguments, including the starting value.

Finally, `Save` saves the results to disk, in this case to a CSV file, but other formats are possible, also.  And the results can of course be printed, also, as the above program demonstrates.

Note that there are many other options and calls.  The main ones are described in the [User Interface](@ref) tab.

!!! tip "Getting help"
    To get help on a command, simply load Grumps in the REPL and type e.g.
    ```
    julia> ?Variables
    ```


