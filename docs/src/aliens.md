# Interacting with other languages

There is only a version of Grumps for Julia.  However, you can call other languages from Julia using one of the `PyCall`, `PythonCall`, or `RCall` packages.  You can load Stata files via the `StatFiles` package.  To call C or Fortran code, see [the Julia documentation](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/).  For those using other software like Gauss and Matlab, consider writing results to disk and then reading them in the software you use.

The code below provides an example in which the output is printed in Julia, Python, and R, respectively.

```
using Grumps, PyCall, RCall


function compute_stuff( meth  )

    s = Sources(                                                            
      consumers = "example_consumers.csv",
      products = "example_products.csv",
      marketsizes = "example_marketsizes.csv",
      draws = "example_draws.csv"  
    )
    
    v = Variables( 
        "choice = income * constant + income * ibu + age * ibu + rc * ibu + rc * abv",
        "share = constant + ibu + abv / constant, ibu, abv, IVgh_ibu, IVgh_abv";
        outsidegood = "product 11"                                
    )
    
    e = Estimator( meth )                                                     
    d = Data( e, s, v ) 
    return grumps!( e, d )           
end

py"""
def print_my_stuff_in_python(x):
	print( "Python: ", x )

"""

R"""
print_my_stuff_in_R <- function(x) cat( "R: ", x, "\n" ) 
"""

function myprogram( )
    sol = compute_stuff( :cheap )
    θcoef =  getθcoef( sol )
    println( "Julia: $θcoef \n" )
    py"print_my_stuff_in_python"(θcoef)
    R"print_my_stuff_in_R"(θcoef)
end


myprogram()
```



