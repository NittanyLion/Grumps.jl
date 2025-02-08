using Grumps


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
    o = Grumps.OptimizationOptions(; memsave = true)     


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


# dev() = true


ENV[ "JULIA_DEBUG" ] = Grumps

begin
    # meth = :cler
    meth = :gmm
    nodes = 11
    draws = 10000
    
    numMicro = 1000

    
    sol = my_estimation( nodes, draws, meth )     
    Grumps.Save("myresults_$(meth)_$(numMicro).txt",sol)

end


