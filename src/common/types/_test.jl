using DataFrames, Printf

import Base.show

include( "_error.jl" )
include( "_print.jl" )
include( "types.jl" )
dfp = DataFrame()

s = Sources( ; 
    consumers = "sources.csv",
    products = dfp,
 )

println( s )
show( stdout, s )