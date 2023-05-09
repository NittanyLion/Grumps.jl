# Estimators

The text below describes the estimators that Grumps can compute.  To select one, refer to the [Estimator choice](@ref) section.

The estimator proposed by Grieco, Murry, Pinkse, and Sagl minimizes the sum $\hat\Omega$ of three objective functions, (minus) a micro loglikelihood, (minus) a macro loglikelihood, and a GMM type quadratic objective function for the product level moments: see [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) for details.  

There are three parameter vectors to be estimated: $\beta,\theta,\delta$.  Since $\beta$ can be easily estimated off $\delta$ and the data, the remainder of this discussion focuses on the estimation of $\theta,\delta$.

* The *full Grumps (CLER)* estimator minimizes $\hat\Omega$ over $\delta$ for a given $\theta$ in an inner loop and then minimizes over $\theta$ in an outer loop.  
    This is efficient, but costly. This estimator is labeled as `:cler` in the code. See [`Estimator( :: Symbol )`](@ref).

* The *cheap Grumps (CLER)*  estimator that is asymptotically equivalent but less expensive computationally. It only minimizes with respect to $\delta$ over minus the sum of the loglikelihoods in an inside loop and minimizes $\hat \Omega$ over $\theta$ in the outside loop. This estimator is labeled `:cheap` in the code. 

* The *mixed data likelihood estimator (MDLE)*, which drops the product level moments term in both the inside and outside loops.  This estimator is *not* conformant (see the paper for its definition) and is therefore inferior to each of the above two estimators. This estimator is labeled `:mdle`

* A fourth *share constrained* estimator maximizes the macro loglikelihood in the inside loop and the sum of the two loglikelihoods in the outside loop.  This  estimator is inferior to the MDLE. This estimator is labeled `:shareconstraint` in the code.

* A *mixed logit*, which would drop the macro loglikelihood entirely. This estimator is labeled `:mixedlogit` in the code. 

Finally, there is an unfinished implementation of a moments estimator, which should not be used.
