
![header](https://joris.pinkse.org/paper/grumps/featured_hu67731c91d8ac62b9ec64ef8cd1d226d8_3264943_808x455_fill_q75_lanczos_smart1.jpg)

# Grumps.jl

### Estimators covered

**Grumps.jl** is a package for computing random coefficients demand models, including:
1. the penalized likelihood estimator of Grieco, Murry, Pinkse, and Sagl (2022)
2. the unpenalized likelihood estimator of Grieco, Murry, Pinkse, and Sagl (2022)
3. GMM type random coefficient models in the style of Berry, Levinsohn, and Pakes (2004)
4. GMM type random coefficient models in the style of Berry, Levinsohn, and Pakes (1995)
5. Mixed logit models
6. Multinomial logit models

It can handle problems of the form

$$(\hat\delta,\hat\theta,\hat\beta) = \argmin_{\delta,\theta,\beta} \big( - \log \hat L(\delta,\theta) + \hat\Pi(\delta,\beta) \big),$$

where $\log \hat L$ is the sum of a micro loglikelihood and a macro loglikelihood and $\hat\Pi$ is a quadratic penalty term.  Any of the three components can be omitted if so desired. 

Typically, $\log \hat L$ is a sum over markets, products, and consumers whereas $\hat\Pi$ is a GMM-style squared norm of a vector-valued sum over markets.  Please see Grieco, Murry, Pinkse, and Sagl (2022) for details.

