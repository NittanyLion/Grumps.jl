# Estimators

The text below describes the estimators that Grumps can compute.  To select one, refer to the [Estimator choice](@ref) section.

The estimator proposed by Grieco, Murry, Pinkse, and Sagl minimizes the sum $\hat\Omega$ of three objective functions, (minus) a micro loglikelihood, (minus) a macro loglikelihood, and a GMM type quadratic objective function: see [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) for details.  

There are three parameter vectors to be estimated: $\beta,\theta,\delta$.  Since $\beta$ can be easily estimated off $\delta$ and the data, the remainder of this discussion focuses on the estimation of $\theta,\delta$.

The *full Grumps (CLER)* estimator minimizes $\hat\Omega$ over $\delta$ for a given $\theta$ in an inner loop and then minimizes over $\theta$ in an outer loop.  This is efficient, but costly.

An estimator that is asymptotically equivalent but less expensive computationally, only minimizes with respect to $\delta$ over minus the sum of the loglikelihoods in an inside loop and minimizes $\hat \Omega$ over $\theta$ in the outside loop: we refer to this as the *cheap* option.

Then there is the *unpenalized maximum likelihood estimator*, which drops the GMM term in both the inside and outside loops.  This estimator is not conformant (see the paper for its definition) and is therefore inferior to each of the above two estimators.

A fourth estimator maximizes the macro loglikelihood in the inside loop and the sum of the two loglikelihoods in the outside loop.  This *share constraint* estimator is inferior to the unpenalized maximum likelihood estimator.

One can also use Grumps to compute a *mixed logit*, which would drop the macro loglikelihood entirely.

Finally, there is an unfinished implementation of a moments estimator, which should not be used.