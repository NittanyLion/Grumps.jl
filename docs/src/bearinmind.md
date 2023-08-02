# Things to bear in mind

## Starting values

The global objective function is nearly convex in $\delta$, so convergence of the inner optimization is generally uneventful.  Although the objective function is not convex in $\theta$, the outer optimization usually achieves the optimum from a single starting value.  However, this is not guaranteed.  

The most frequent case in which this would go wrong is when one or more of the $\theta^\nu$ coefficients goes to zero and gets stuck.  This is more likely to happen when there are identification problems, e.g. when $\theta^z \approx 0$ and the product level moments do not provide much identifying power.  Just try a few other starting values.

## Memory consumption

The program will become memory-hungry when the number of random coefficients is increased (assuming micro data are used).    Look at the `memsave` option to reduce memory consumption.

## Zero shares

The estimation procedure in [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) offers some robustness to shares that are equal to or very close to zero.  However, that requires that the product level moments are overidentified.

## Efficiency

The estimation procedure in [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) is efficient if an optimal weight matrix for the product level moments (GMM) portion is used whenever there is overidentification in the product level moments.  This is usually accomplished in a two step procedure.  

The default procedure in Grumps is a single step procedure with weight matrix $(B^T B)^{-1}$.  This produces estimates that are consistent with valid standard errors but that are not necessarily fully efficient.  

See [`DataOptions()`](@ref) on how to achieve full efficiency using a two step procedure.  

!!! tip "Starting values of second stage"
    One can use the first stage estimates as starting values of the second stage.  Since the first stage estimates converge at the optimal rate, also, this second stage optimization should converge quickly.


## Floating point numbers

All numbers should be in the same floating point format.  The default (and only heavily tested) format is Float64, i.e. a 64-bit float.  But the code is designed to handle other formats.  This could be attractive if greater precision is desired.  So one could use some form of BigFloat, at the expense of increased memory use and a substantial increase in computation time.

## Nesting of memsave 

If the `memsave` option (see [Optimization options](@ref) and [Memory conservation](@ref)) is set to `true` then Grumps will use some low level code to avoid having to repeatedly allocate and free memory.  What this means is that it is a bad idea to have `grumps!` called from multiple threads simultaneously: from multiple processes should be fine.  If you do not know what this means then you should be ok. 







