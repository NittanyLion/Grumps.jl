

 # set relative path of location of Grumps.jl; won't be needed 
 # once Julia is a formal package
push!(LOAD_PATH, "../../src")                              



using Grumps, LinearAlgebra, PyCall#, RCall


function compute_stuff( meth  )

    s = Sources(                                                            
      consumers = "example_consumers.csv",
      products = "example_products.csv",
      marketsizes = "example_marketsizes.csv",
      draws = "example_draws.csv"  
    )
    
    v = Variables( 
        "choice = income * constant + income * ibu + age * ibu + rc * ibu + rc * abv",
        "share = constant + ibu + abv | constant, ibu, abv, IVgh_ibu, IVgh_abv";
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

# R"""
# print_my_stuff_in_R <- function(x) cat( "R: ", x, "\n" ) 
# """

function myprogram( )
    sol = compute_stuff( :cheap )
    θcoef =  getθcoef( sol )
    println( "Julia: $θcoef \n" )
    py"print_my_stuff_in_python"(θcoef)
    # R"print_my_stuff_in_R"(θcoef)
end


myprogram()

