
![header](https://joris.pinkse.org/paper/grumps/featured_hu67731c91d8ac62b9ec64ef8cd1d226d8_3264943_808x455_fill_q75_lanczos_smart1.jpg)

# Grumps.jl version 0.2.5

## Overview

**Grumps.jl** is a package for computing random coefficients demand models using consumer and product level data. The main estimators are introduced in [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/), including:
1. the conformant likelihood with exogeneity restrictions (CLER) estimator
2. an asymptotically equivalent less expensive alternative thereof
3. the mixed data likelihood estimator (MDLE)
4. the share constrained likelihood estimator

    In addition, other estimators have been implemented: 

5. mixed logit models (consumer level data only)
6. multinomial logit models (consumer level data only)
7. GMM type random coefficient models in the style of Berry, Levinsohn, and Pakes (2004) (in process, not recommended)


In the notation of the paper, it solves problems of the form

$$(\hat\delta,\hat\theta,\hat\beta) = \text{argmin}_{\delta,\theta,\beta} \big( - \log \hat L(\delta,\theta) + \hat\Pi(\delta,\beta) \big),$$

where $\log \hat L$ is the sum of a micro loglikelihood and a macro loglikelihood and $\hat\Pi$ is a quadratic penalty term.  Any of the three components can be omitted if so desired. 

Typically, $\log \hat L$ is a sum over markets, products, and consumers whereas $\hat\Pi$ is a GMM-style squared norm of a vector-valued sum over markets.  Please see [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) for details.

Several extensions are possible, which may require additions to the code. 

## Documentation

This documentation describes the use of the Grumps computer package.  It does not describe the estimators or algorithms.  Please refer to [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) for that.  In addition, the code itself is documented, also.

## Limitations

This is still a preliminary version of Grumps, so please advise [Joris Pinkse](mailto://pinkse@gmail.com) of any bugs, problems, shortcomings, missing features, etcetera.  Features it does not currently possess include:
1. sparse quadrature or similar integration methods
2. distributed computing
3. GPUs
4. statistics other than coefficients, e.g. elasticities
5. integration methods for the micro portion of the GMM estimator other than quadrature
6. traditional GMM; see [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) for details
7. standard errors for some of the estimators
8. detailed sanity checks

## License

All of this code is subject to the MIT license.  This code includes a modified version of the Newton Method with Trust Regions code in the Optim package, which is also subject to the MIT license.
