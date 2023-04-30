# Miscellanea

## Tips

* In most programming languages, it is a bad idea to use global variables.  This is especially true in Julia.  So bury any variable definitions, etcetera, inside a function.  You may incur a significant performance hit if you don't.
* If one used an estimated $\sigma_\xi^2$ in a two stage procedure, then the estimated $\sigma_\xi^2$ can be made arbitrarily small by adding many regressors to the $\delta$ on $x$ regression.  This is a bad idea since it artificially puts all the weight on the product level moments.


