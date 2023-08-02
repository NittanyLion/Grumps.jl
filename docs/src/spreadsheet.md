# Spreadsheet formats


Recall that Grumps can take data from four different sources and in different formats.  Currently, only *CSV files* and *DataFrames* are implemented.  Recall that not all four sources are required for all estimators.  

!!! tip "Files are preferable to dataframes"
    There is one advantage to providing file names instead of dataframes, and that is that Julia can release the memory allocated by the memory after return of the [`Data()`](@ref) call.

As mentioned elsewhere, there is one spreadsheet (the *products* spreadsheet) that contains data on products, including e.g. price, market share, features, product level instruments ($s,x,b$ in the paper).  If consumer choice data are used then such data can be entered via the *consumers* spreadsheet, which includes data on individual consumer choices, demographic characteristics, etcetera: anything that would typically have an $i$ subscript in other words ($y,z$ in the paper).  A *market size* spreadsheet would contain information on the size of each market, i.e. the population in that market, which is only needed if the macro portion of the likelihood is to be used ($N$ in the paper).  Finally, a *demographic draws* spreadsheet can be provided to be used in the macro likelihood portion of the objective function, i.e. $z$ draws to use in the macro integration.  The format of each of these spreadsheets is described below.

In the examples below, the data are comma separated, but that is not necessary: other formats can be specified in the [`Sources()`](@ref) call.  Column ordering is irrelevant.

!!! warning "Cases and spaces"
    For all spreadsheets be mindful of case and spaces.  That means omit spaces and be consistent in lower case versus upper case. For readability the spreadsheets below contain extra space i.e. they are aligned by comma; this is not advisable.  

## Linking between spreadsheets

Grumps is flexible in naming conventions.  However, this requires that certain identifiers are common across spreadsheets. The following conventions should hold:

* A market level identifier should be present in all spreadsheets using the same column heading. In the example below, this column heading is `market`. 
* The values of the `market` column in the marketsize spreadsheet should be unique. These values should link to the `market` columns in the *product*, *consumer*, and *draws* datasets.
* The values of one column of the *product* dataset should be a unique identifier of a product within a market. In the example below, the heading for this column is `product`. 
* The values of one column in the *consumer* dataset should link to the unique identifier column of the *product* dataset. In the example below, the heading for this column is `choice`. 
* Any variables used as demographics ($z$) should be present in both the *consumer* and *draws* datasets using identical column headings.  




## Product characteristics

Below are the first few lines of a CSV file.  

```
ibu ,  abv, share, IVgh_ibu, IVgh_abv, IVj_ibu, IVj_abv, market  , product
1.09, 1.01, 0.01 , 12.57   , 11.45   , 4.78   , 5.09   , market 1, product 1
2.85,-0.10, 0.13 , 10.52   ,  8.55   , 5.21   , 5.23   , market 1, product 2
2.31, 0.55, 0.02 , 4.54    ,  7.26   , 5.91   , 5.52   , market 1, product 3
```

The column headings are variable names.  Each row corresponds to a (market, product) pair and both these columns are
required, albeit that the columns can have different names; *market* and *product* are just the defaults.  The markets have especially boring
names in this example, but any string goes.  The same is true for products.  This spreadsheet does *not* need to include the outside
good (indeed, leave it out) and shares would thus typically sum to a number less than one.  Which columns are to be used and where is 
determined by the [`Variables`](@ref) call.  To use dummy variables, just insert a column with the corresponding characteristics (there can be multiple categories, which can be descriptive (e.g. strings)), which Grumps can turn into dummy variables automatically, as described in the [`Variables`](@ref) documentation.

The *market* and *product* columns are required and *share* is required if the macro loglikelihood is to be included in the objective function.


## Consumer characteristics

Below are the first few lines of a CSV file.

```
income,  age, market  ,     choice
 -1.20, 1.24, market 1,  product 8
 -0.64, 0.36, market 1, product 11
 -0.65, 1.32, market 1,  product 4
 -0.82, 0.77, market 1, product 11
```

The column headings are again variable names.  Each row corresponds to a consumer in the observed micro sample. Here, we need both market and choice, but the columns do not have to have those (default) headings.  The markets and products could have had more descriptive names (e.g. "Pennsylvania" instead of "market 1"), and the column headings could have been different as long as the above linking conventions are followed. 

In the consumer level spreadsheet, a consumer choice column and a market column are required and one should use at least one consumer characteristic to differentiate the micro likelihood from the macro likelihood.

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

Each row corresponds to a market.  Again, the column headings can be adjusted and the ones presented here are the default ones.  Both columns are required.


## Draws

Below are the first few lines of a CSV file.

```
income,  age, market
 -1.60, 1.19, market 1
 -2.93, 1.23, market 1
 -1.78, 1.58, market 1
 -1.14, 1.70, market 1
```

The rows of this spreadsheet correspond to consumers in the population, albeit their choice need not be observed.  The format and limitations for the draws spreadsheets is essentially the same as the other spreadsheets, but here each line corresponds to a (draw,market) pair. For markets for which market size information is available, one typically needs a number of demographic draws no less than the number of Monte Carlo draws to be used, where each draw is a vector of demographic characteristics that would be observed in the micro sample.  

!!! warning "Draws and default macro integrator options"
    Unless specified otherwise, the default macro integrator uses Monte Carlo integration with $R = 10,000$ draws unless otherwise specified.  If one does not specify randomization then the default macro integrator simply uses the first $R$ lines of draws for each market for demographics ($z$ draws) and combines them with $R$ draws from the distribution of the random coefficients ($\nu$ draws), both of which are then interacted with the product level regressors ($x$ variables).  If the spreadsheet does not contain enough rows corresponding to a market then the program will cycle and throw a warning.  With randomization with replacement, $R$ numbers are drawn from the draws spreadsheet regardless of the number of lines in the spreadsheet.  Without replacement, the same occurs and if the spreadsheet does not contain enough lines corresponding to the market, all lines are added and then the procedure is repeated.  In other words, there is replacement by necessity.  Again, a warning will be displayed. With randomization, the random numbers are drawn separately for each market.

