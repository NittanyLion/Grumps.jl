# Miscellanea


## Reducing data load times     

Grumps uses three packages that have significant overhead when they are first called.  This is most noticeable when loading small datasets and mostly an issue if you run Julia in batch mode from the command line, as opposed to from within the REPL (except on the first run from within the REPL).  To avoid this overhead, one can use the `PackageCompiler` package.  To use it, do the following:

1. add the PackageCompiler using `]add PackageCompiler` in the REPL.
2. copy the contents of the `extras` folder on the github Grumps repository to your computer
3. run `julia makesystemimage.jl`
4. then, in the future, run `julia -J *location of image.so* *other options*`

!!! warning "New Julia versions"
    This procedure would have to be repeated every time you upgrade Julia to a new version"

## Random tips

* In most programming languages, it is a bad idea to use global variables.  This is especially true in Julia.  So bury any variable definitions, etcetera, inside a function.  You may incur a significant performance hit if you don't.
* If one used an estimated $\sigma_\xi^2$ in a two stage procedure, then the estimated $\sigma_\xi^2$ can be made arbitrarily small by adding many regressors to the $\delta$ on $x$ regression.  This is a bad idea since it artificially puts all the weight on the product level moments.
* If the splash screen bothers you, you can turn it off by writing `const splashprobs = zeros( 4 )` before running `using Grumps`.


