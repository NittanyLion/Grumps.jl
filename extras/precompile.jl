using FastGaussQuadrature, CSV, DataFrames


function stuff()
    df = CSV.File( "example_marketsizes.csv" ) |> DataFrame
    x = gausshermite( 31 )
    return df, x
end


stuff()

