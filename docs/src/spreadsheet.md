# Spreadsheet formats


Recall that Grumps can take data from four different sources and in different formats.  Currently, only *CSV files* and *DataFrames* are implemented.  Recall that not all four sources are required for all estimators.

## Product characteristics

Below are the first few lines of a CSV file.  

```
ibu ,  abv, share, IVgh_ibu, IVgh_abv, IVj_ibu, IVj_abv, market  , product
1.09, 1.01, 0.01 , 12.57   , 11.45   , 4.78   , 5.09   , market 1, product 1
2.85,-0.10, 0.13 , 10.52   ,  8.55   , 5.21   , 5.23   , market 1, product 2
2.31, 0.55, 0.02 , 4.54    ,  7.26   , 5.91   , 5.52   , market 1, product 3
```

The column headings are variable names.  Each line corresponds to a (market, product) pair.  The markets have especially boring
names in this example, but any string goes.  The same is true for products.  This spreadsheet does *not* need to include the outside
good (indeed, leave it out) and shares would typically sum to a number less than one.  Which columns are to be used and where is 
determined by the [`Variables`](@ref) call.