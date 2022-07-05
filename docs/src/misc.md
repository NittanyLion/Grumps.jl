# Miscellanea

## Reducing data load times     

Grumps uses three packages that have significant overhead when they are first called.  This is most noticeable when loading small datasets.  To avoid this overhead, one can use the `PackageCompiler` package.  To use it, do the following:

1. add the PackageCompiler using `]add PackageCompiler` in the REPL.
2. copy the contents of the `extras` folder on the github Grumps repository to your computer
3. run `julia makesystemimage.jl`
4. then, in the future, run `julia -J *location of image.so* *other options*`

**Note that this procedure would have to be repeated every time you upgrade Julia to a new version**