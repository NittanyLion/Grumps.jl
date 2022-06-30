# Grumps.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://NittanyLion.github.io/Grumps.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://NittanyLion.github.io/Grumps.jl/dev)
[![Build Status](https://github.com/NittanyLion/Grumps.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/NittanyLion/Grumps.jl/actions/workflows/CI.yml?query=branch%3Amain)

![header](https://joris.pinkse.org/paper/grumps/featured_hu67731c91d8ac62b9ec64ef8cd1d226d8_3264943_808x455_fill_q75_lanczos_smart1.jpg)

# Grumps.jl

## Overview

**Grumps.jl** is a package for computing random coefficients demand models, including:
1. the penalized likelihood estimator of Grieco, Murry, Pinkse, and Sagl (2022)
2. the unpenalized likelihood estimator of Grieco, Murry, Pinkse, and Sagl (2022)
3. GMM type random coefficient models in the style of Berry, Levinsohn, and Pakes (2004)
4. GMM type random coefficient models in the style of Berry, Levinsohn, and Pakes (1995)
5. Mixed logit models
6. Multinomial logit models


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