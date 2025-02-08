using Grumps
using Revise, CSV, DataFrames, DelimitedFiles, Random
using LinearAlgebra
using DataFramesMeta

Random.seed!(16802)

function makeCPS(;numDraws=10_000)
    # Description: reads in raw CPS data, draws random sample, 
    # and creates varaibles for estimation
    #
    # Inputs
    # numDraws      | Number of random draws (default = 10_000)

    df_cps = CSV.read("CPS_households.csv", DataFrame)

    @subset!(df_cps, :hhincome.>0)

    years = 1980:2005
    nYrs = length(years)
    df_draws = DataFrame()
    for ix in years
        df_tmp = df_cps[df_cps.year.==ix,[:year, :rural, :hhincome, :married, :numchildren, :age]]
        sz = size(df_tmp)[1]
        idx = rand(1:sz,numDraws)
        df_draws = vcat(df_draws, df_tmp[idx,:])
    end

    @transform!(df_draws, :urban = 1 .- :rural)
    @transform!(df_draws, :fam_size = 1 .+ :married .+ :numchildren)
    @transform!(df_draws, :income = :hhincome./10_000)
    @transform!(df_draws, :inc2 = :income.^2)
    df_draws.log_inc = log.(df_draws.hhincome)

    CSV.write("gmy_draws.csv",df_draws)
end


function makeDataForEstimation(beg_year, end_year, num_cons=nothing)
    # Description: Function to subset data
    #
    # Inputs:
    # beg_year  | first year
    # end_year  | last year
    # num_cons  | number of micro consumers per year

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

makeCPS()


# Estimate mBLP with Grumps

function my_estimation(nodes, draws, meth)
    # set which files contain the data to be used
    s = Sources(                                                            
      consumers = "consumer.csv",
      products = "product.csv",
      marketsizes = "market.csv",
      draws = "draws.csv"  
    )

    # set the specification to be used
    v = Variables( 
    # these are the z_{im} * x_{jm} terms in the paper                                                         
    interactions =  [                                                   
        :log_inc :msrp; 
        :fam_size :van;
        :urban :truck;
        :log_inc :constant;
        ],
        # these are the x_{jm} * ν terms in the paper
        randomcoefficients =  [:log_mpg, :suv],     
        # these are the x_{jm} terms in the paper                            
        regressors =  [ :constant; :log_mpg; :log_hp; :log_footprint; :log_curbweight; :suv; :van; :truck; :msrp],      
        # these are the b_{jm} terms in the paper                      
        instruments = [:constant; :log_mpg; :log_hp; :log_footprint; :log_curbweight; :suv; :van; :truck; :lag_pl_con; :IV1; :IV3], 
        # these are not needed for the estimators in the paper, just for GMM     
        microinstruments = [                                                
            :income :constant; 
        ],
        # this is the label used for the outside good
        outsidegood   = "outsidegood",   
        market          = :year,
        share           = :share,
        product         = :model,
        dummies         = [:year],
        # nuisancedummy   = :make
    )
    # creates an estimator object
    e = Estimator( meth )                                                     

    # redundant unless you wish to save memory
    o = Grumps.OptimizationOptions(; memsave = false)     


    # this puts the data into a form Grumps can process
    d = Data( e, s, v; replicable = true ) 
    # there are longhand forms if you wish to set additional parameters
    # d = Data( e, s, v, ms, Ms; replicable = true ) 

    # compute estimates using automatic starting values
    # sol = grumps!( e, d )  
    sol = grumps!(e,d,o)         
    # long version to set more options                                          
    # sol = grumps!( e, d, o, nothing, seo  )                                 
    return sol

end

begin
    meth = :cler
    nodes = 11
    draws = 10_000
    
    numMicro = 1_000

    makeDataForEstimation(1981,1995,numMicro)

    sol = my_estimation( nodes, draws, meth )     
    Grumps.Save("myresults_$(meth)_$(numMicro).txt",sol)

end


