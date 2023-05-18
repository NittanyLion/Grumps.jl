# CLER Tutorial Using Car Data

## Introduction 

This tutorial explains how to use the package `Grumps.jl` to estimate demand, as described in Grieco, Murry, Pinkse, Sagl (2023). Although we do not have the same exact data and we deviate from
the empirical specification, the exercise is meant to mimic the data environment in Petrin (2002), who estimates the demand for new cars using aggregate data on national shares and prices, and consumer survey data from the Consumer Expenditure Survey.  You can find the data and code at  [`extras/charliestutorial`](https://github.com/NittanyLion/Grumps.jl/tree/main/extras/charliestutorial)

First, we describe the automobile data used for the tutorial and write a bit of Julia code to process the data so that it can be used by `Grumps`.   Second, we step through using `Grumps`.


## Data

### Data Description

The data were originally collected by Grieco, Murry, and Yurukoglu (2023) and are, collectively, a subset of the data used in that paper. 
We use Wards Automotive product-level data from 1980-2005, which includes prices, quantities, and vehicle attributes. 
The data file is called `gmy_product.csv`. *Disclosure: The model names are anonymized and the variables have been slightly perturbed. These data should not be used for any commercial purpose.*

We also use survey data from the automobile supplement to the Consumer Expenditures Survey from 1980--2005, where for each respondent we observe which car they purchased and various household characteristics. 
The data file is called `gmy_cex_consumer.csv`.

In order to simulate the population of potential buyers, we use demographics from the consumer expenditure survey for the same time frame.
The raw CPS data file is called `CPS_households.csv`. 
We will need to process this data a bit. 

Lastly, there is data on market sizes. 
This is in the data file called `gmy_market.csv`


### Data Processing

Let's start working with the data in Julia. First let's load all of the packages we will need.

```julia
using Grumps
using Revise, CSV, LinearAlgebra, DelimitedFiles, Random
using DataFrames, DataFramesMeta

Random.seed!(16802)
```

### Process the CPS data
Next we will write a function to process the CPS data to make it look like the CEX survey data. In the end, these files should have identical variable names. 

```julia
function makeCPS(;numDraws=10_000)
# Description: reads in raw CPS data, draws random sample, 
# and creates varaibles for estimation
#
# Inputs:
# numDraws      | Number of random draws (optional, default = 10_000)

@subset!(df_cps, :hhincome.>0)

years = 1980:2005
nYrs = length(years)
df_draws = DataFrame()
for ix in years
    df_tmp = df_cps[df_cps.year.==ix,[:year, :rural, :hhincome, :married, :numchildren, :age]]
    sz = size(df_tmp)[1]
    idx = rand(1:sz,10_000)
    df_draws = vcat(df_draws, df_tmp[idx,:])
end

@transform!(df_draws, :urban = 1 .- :rural)
@transform!(df_draws, :fam_size = 1 .+ :married .+ :numchildren)
@transform!(df_draws, :income = :hhincome./10_000)
@transform!(df_draws, :inc2 = :income.^2)
df_draws.log_inc = log.(df_draws.hhincome)

CSV.write("gmy_draws.csv",df_draws)
end
```
This function reads in `CPS_households.csv` to a data frame, subsets to only positive incomes, then for each year draws 10,000 random people. Then it generates new variables to match with the CEX survey data and writes the new data to `gmy_draws.csv`.

Now let's just call this function to process the CPS data.
```julia
makeCPS()
```

### Subset the data
We may want to run our estimation on datasets of different sizes, so next I create a function to subset the data for the final estimation run and saves them to separate files that we will later load with the estimation routine. The following function subsets the data in terms of markets (years) and the number of micro consumers we use from the survey data. 

```julia
function makeDataForEstimation(beg_year, end_year, num_cons=nothing)
    # Description: Function to subset data
    #
    # Inputs:
    # beg_year  | first year
    # end_year  | last year
    # num_cons  | number of micro consumers per year (optional, default=nothing)

    # Consumer Sample
    df_cons = CSV.read("gmy_cex_consumer.csv",DataFrame)
    @subset!(df_cons,:income.>0)
    @transform!(df_cons, :log_inc = log.(:income))
    @transform!(df_cons, :income = :income./10_000)
    @transform!(df_cons, :inc2 = (:income).^2)
    @subset!(df_cons, :year .>= beg_year)
    @subset!(df_cons, :year .<= end_year)

    if num_cons !== nothing        # Further subsets the consumer data (optional)
        years = unique(df_cons.year)
        df_new = DataFrame()
        for ix in years
            df_tmp = df_cons[df_cons.year.==ix,:]
            sz = size(df_tmp)[1]
            idx = rand(1:sz,num_cons)
            df_new = vcat(df_new, df_tmp[idx,:])    
        end
        CSV.write("consumer.csv",df_new)
    else
        CSV.write("consumer.csv",df_cons)
    end

    # Products
    df_prod = CSV.read("gmy_product.csv", DataFrame)
    @subset!(df_prod, :year .>= beg_year)
    @subset!(df_prod, :year .<= end_year)
    CSV.write("product.csv", df_prod)

    # Markets
    df_market = CSV.read("gmy_market.csv", DataFrame)
    @subset!(df_market, :year .>= beg_year)
    @subset!(df_market, :year .<= end_year)
    CSV.write("market.csv", df_market)
    
    # CPS draws
    df_draws = CSV.read("gmy_draws.csv", DataFrame)
    @subset!(df_draws, :year .>= beg_year)
    @subset!(df_draws, :year .<= end_year)
    CSV.write("draws.csv", df_draws)   
end
```

Run this function, specifying the years and that we only want 100 micro consumers oer year. 
```julia
makeDataForEstimation(1985,2000,100)
```


## `Grumps` Package Installation

`Grumps.jl` is available from the `Julia` package repository. To add it to your installation

```julia
using Pkg
Pkg.add("Grumps")
```

Julia makes use of parallelization. To invoke `Julia` with 4 threads on your local machine (for example) invoke `Julia` in the following way.

```bash
julia -t 4 "myprog.jl"
```

See the [Installation and invocation](https://nittanylion.github.io/Grumps.jl/dev/installation/) page on the docs for more detail. 




## Estimation 

Now we are ready to use `Grumps.jl` to estimate demand for cars. The way to call the estimator is through the following function call
```julia
sol = grumps!(e,d,o)
```
where `e` is the "Estimator" structure that tell `Grumps` which estimator to use, `d` is the "Data" structure that tells `Grumps` where the data is and which variables to use, and `o` is a "Estimation Options" structure that supplies various computation options to the program. The function call returns a structure that we have names `sol`.

### Estimator
First, let's pick a estimator, `e`. The main estimator described in the paper is the `:cler` estimator. The code also implements is an alternative (and asymptotically equivalent) estimator called `:cheap` that uses less memory and should be faster. Other options are in the following table

Estimator    | Description 
---          | ---
`:cler`      | main estimator described in the paper
`:cheap`     | computationally cheaper version of `:cler`
`:mdle`      | version of `:cler` without the product-level restrictions, $\hat{\Pi}$ 
`:shareconstraint` | Further implements the BLP contraction mapping to get $\delta$'s
`:mixedlogit` | Uses only the likelihood of individual choices

We will implement `:cler` for the purposes of the tutorial. If this uses too much memory for you, switch to using the `:cheap` method.
```julia
e = Estimator( :cler )
```

### Data
Now let's tell Grumps about our data. The data structure is formed by the following call:
```julia
d = Data( e, s, v ) 
```
which takes `e`, the same "Estimator" object as above, `s`, a "Sources" object, and `v`, a "Variables" object. We tell Grumps where the data are located with the following source object. 
```julia
s = Sources(                                                            
  consumers = "consumer.csv",
  products = "product.csv",
  marketsizes = "market.csv",
  draws = "draws.csv"  
)
```

### Variables
Lastly, we can tell Grumps about the specification of the model, or which "Variables" to include. This can be a large object with many sub-structures because the model can be pretty complicated. 

#### Demographic Interactions
List interactions between car attributes and demographic characteristics in the "interactions" sub-object. List the demographic variable first and the product attribute
```julia
v = Variables( 
    # these are the z_{im} * x_{jm} terms in the paper                                                         
    interactions =  [                                                   
        :log_inc :msrp; 
        :fam_size :van;
        :urban :truck;
        :log_inc :constant;
        ],
```

#### Random Coefficients 
Next can specify the random coefficients. If you want more than one, you can separate them with a ";".
```julia
    # these are the x_{jm} * ν terms in the paper
    randomcoefficients =  [:log_mpg],
```

#### Linear Utility Coefficients
Next we can specify the product attributes that enter into the linear part of the utility and the instruments we will use as part of the product level exclusion restrictions. Notice how we include price as a regressor but exclude it as an instrument. Here, we are including two instruments, so that the model in over-identified. 
```julia
    # these are the x_{jm} terms in the paper                            
    regressors =  [ :constant; :log_mpg; :log_hp; :log_footprint; :log_curbweight; :suv; :van; :truck; :msrp],      
    # these are the b_{jm} terms in the paper                      
    instruments = [:constant; :log_mpg; :log_hp; :log_footprint; :log_curbweight; :suv; :van; :truck; :lag_pl_con; :IV1; :IV3], 
```
#### Other Variables
Lastly there are other variables we have the option to specify in the model. We can tell Grumps what to call the outside good, what we call the market in our datasets (in the car data, a market is `:year`), what variable contains product shares (`:share`), and what variable denotes different products (`:model` in our case). Optionally, we can include a categorical variable that Grumps can include as dummies, and if there is a dummy variable that we want to control for, but we don't care about the coefficients, we can list that as a "nuisancedummy." Here we include year and make effects, and we don't care about the make coefficients. 
```julia
    outsidegood   = "outsidegood",   
    market          = :year,
    share           = :share,
    product         = :model,
    dummies         = [:year],
    # nuisancedummy   = :make # I don't have this in the data, but if I did...
)
```

#### Estimation 
 Now we could put everything we did to set up estimation into a function and call that function. It will have the following structure where the "..." is just a placeholder for the code in the blocks above. 
 ```julia
function my_estimation(nodes, draws, meth)
    e = Estimator(meth)
    s = Sources(...)
    v = Variables(...)
    d = Data(...)

    sol = grumps!(e,d)  
end

nodes = 11
draws = 2_000
meth = :cheap

sol = my_estimation(nodes, draws, meth)
 ```

We can use the "Save" feature of Grumps to write our solution structure to a text file. 
```julia
Grumps.Save("myresults_$(meth).txt",sol)
```

If everything is in a `.jl` file, the we call the file from the command line, specifying the number of threads we would like to use. See the accompanying `tutorial.jl` file to see the finished result. Iterations on my laptop using six threads take about 200 seconds, so you'll have to wait a few minutes before you start seeing iteration output. 


## References

Petrin, Amil. "Quantifying the benefits of new products: The case of the minivan." Journal of political Economy 110, no. 4 (2002): 705-729.

Grieco, Paul and Murry, Charles and Pinkse, Joris and Sagl, Stephan. "Conformant and Efficient Estimation of Discrete Choice Demand Models." working paper, Penn State University (2023).

Grieco, Paul L. E., Charles Murry, and Ali Yurukoglu. “The Evolution of Market Power in the US Auto Industry.” Working Paper. Working Paper Series. National Bureau of Economic Research, July 2021. https://doi.org/10.3386/w29013.


## Appendix A: Description of Datasets

### gmy_product.csv

Unit of observation is a year-model.

Variable | Type | Description
--- | --- | ---
year           | float   |   year of sales / modelyear
model          | int     |   unique model ID (same model is same ID across years)
share          | float   |   sales / market size
msrp           | float   |   price of the the vehicle
log_footprint  | float   |   car height in inches
log_curbweight | float   |   (p 50) curbweight
log_hp         | float   |   horsepower
log_mpg        | float   |   MPG rating (city or combined if city missing)
regionUS       | float   |   dummy: brand region is US (eg Chrysler is US, Fiat is EU)
regionEU       | float   |   dummy: brand region is EU (eg Chrysler is US, Fiat is EU)
regionASIA     | float   |   dummy: brand region is Asia
EV             | float   |   dummy: car is completely electric powered or a PHEV
make2num       |  int    |   vehicle make ID (smallest britsh makes combined into one)
suv            | int     |   dummy: vehicle is SUV or CUV
truck          | int     |   dummy: vehicle is a pickup truck
van            | int     |   dummy: vehicle is a van  
car            | float   |   dummy: aggregate of sedan, couple, hatchback and other car styles
lag_pl_con     | float   |   lagged real exchage rate of production country
iv_prod        |  int    |   dummy: production country == hq country
IV1            |  float  |   number of products available for the same vehicle type
IV2            |  float  |   Ghandi-Houde IV for horsepower
IV3            |  float  |   GH IV for mpg
IV4            |  float  |   GH IV for footprint
IV5            |  float  |   GH IV for curbweight
IV6            |  float  |   number of products available for the same HQ region
IV7            |  float  |   number of products available for the same type and HQ region


### gmy_market.csv

Unit of observation is a year.

Variable | Type | Description
--- | --- | ---
year        | int     |   year of sales / modelyear
N           | float   |   Total number of US household that year, Census (unit of obs: year)



### gmy_cex_consumer.csv

Unit of observation is a suvey response. A survey takes place in a single year, and always includes a choice of a car. 

Variable | Type | Description
--- | --- | ---
year        | int     |   year of sales / modelyear
choice      | int     | model ID corresponsing to purchase decision 
income      | float   | househild income
fam_size    | int     | number of household members
urban       | int     | dummy: 1 if the household location is urban. 


### gmy_draws.csv

Unit of observation is a survey response. A survey takes place in a single year. These are population draws from the Consumer Population Survey.  

Variable | Type | Description
--- | --- | ---
year        | int     |   year of sales / modelyear
weight      | float   | CPS sampling weights. 
rural       | int     | dummy: household in non-urban location 
hhincome    | float   | househild income
married     | int     | dummy: 1 if respondent married
numchildren | int     | number of children in household
other variables not used | |


