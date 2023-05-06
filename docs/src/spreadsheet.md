# Spreadsheet formats


Recall that Grumps can take data from four different sources and in different formats.  Currently, only *CSV files* and *DataFrames* are implemented.  Recall that not all four sources are required for all estimators.  

!!! tip "Files are preferable to dataframes"
    There is one advantage to providing file names instead of dataframes, and that is that Julia can release the memory allocated by the memory after return of the [`Data`](@ref) call.

As mentioned elsewhere, there is one spreadsheet (the *products* spreadsheet) that contains data on products, including e.g. price, market share, features, product level instruments ($s,x,b$ in the paper).  If consumer data are used then such data can be entered via the *consumers* spreadsheet, which includes data on individual consumer choices, demographic characteristics, etcetera: anything that would typically have an $i$ subscript in other words ($y,z$ in the paper).  A *market size* spreadsheet would contain information on the size of each market, i.e. the population in that market, which is only needed if the macro portion of the likelihood is to be used ($N$ in the paper).  Finally, a *demographic draws* spreadsheet can be provided to be used in the macro likelihood portion of the objective function, i.e. $z$ draws to use in the macro integration.  The format of each of these spreadsheets is described below.

In the examples below, the data are comma separated, but that is not necessary: other formats can be specified in the [`Sources`](@ref) call.  Column ordering is irrelevant.

!!! warning "Cases and spaces"
    For all spreadsheets be mindful of case and spaces.  That means omit spaces and be consistent in lower case versus upper case. For readability the spreadsheets below contain extra space i.e. they are aligned by comma; this is not advisable.  


## Product characteristics

Below are the first few lines of a CSV file.  

```
ibu ,  abv, share, IVgh_ibu, IVgh_abv, IVj_ibu, IVj_abv, market  , product
1.09, 1.01, 0.01 , 12.57   , 11.45   , 4.78   , 5.09   , market 1, product 1
2.85,-0.10, 0.13 , 10.52   ,  8.55   , 5.21   , 5.23   , market 1, product 2
2.31, 0.55, 0.02 , 4.54    ,  7.26   , 5.91   , 5.52   , market 1, product 3
```

The column headings are variable names.  Each line corresponds to a (market, product) pair and both these columns are
required, albeit that the columns can have different names; *market* and *product* are just the defaults.  The markets have especially boring
names in this example, but any string goes.  The same is true for products.  This spreadsheet does *not* need to include the outside
good (indeed, leave it out) and shares would thus typically sum to a number less than one.  Which columns are to be used and where is 
determined by the [`Variables`](@ref) call.  To use dummy variables, just insert a column with the corresponding characteristics (there can be multiple categories, which can be descriptive (e.g. strings)), which Grumps can turn into dummy variables automatically, as described in the [`Variables`](@ref) documentation.

## Consumer characteristics

Below are the first few lines of a CSV file.

```
income,  age, purchase, second,   market,     choice
 -1.20, 1.24,        8,     11, market 1,  product 8
 -0.64, 0.36,       11,      8, market 1, product 11
 -0.65, 1.32,        4,      3, market 1,  product 4
 -0.82, 0.77,       11,      4, market 1, product 11
```

The columns are again variable names.  Here, we need both market and choice, but the columns do not have to have those (default) headings.  Indeed, choice could have been replaced with purchase, and nothing would have been different, albeit that the same product
and market descriptors should be used across data sources (spreadsheets).  The markets and products could have had more descriptive names (e.g. "Pennsylvania" instead of "market 1"), and the column headings could have been different.

## Market sizes

Below are the first few lines of a CSV file.

```
N     , market
100000, market 1
100000, market 2
100000, market 3
100000, market 4
100000, market 5
```

Note that there is one line per market.  Again, the column headings can be adjusted and the ones presented here are the default ones.


## Draws

Below are the first few lines of a CSV file.

```
income,  age, market
 -1.60, 1.19, market 1
 -2.93, 1.23, market 1
 -1.78, 1.58, market 1
 -1.14, 1.70, market 1
```

The format and limitations for the draws spreadsheets is essentially the same as the other spreadsheets, but here each line corresponds to a (draw,market) pair. For markets for which market size information is available, one typically needs a number of demographic draws no less than the number of Monte Carlo draws to be used, where each draw is a vector of demographic characteristics that would be observed in the micro sample.  


