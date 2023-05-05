# Things to bear in mind

## Starting values

The global objective function is nearly convex in $\delta$, so convergence of the inner optimization is generally uneventful.  Although the objective function is not convex in $\theta$, the outer optimization often achieves the (near) optimum from a single starting value.  However, this is not guaranteed.  

The most frequent case in which this would go wrong is when one or more of the $\theta^\nu$ coefficients goes to zero and gets stuck.  This is more likely to happen when there are identification problems, e.g. when $\theta^z \approx 0$ and the product level moments do not provide much identifying power.  Just try a few other starting values.

## Number of random coefficients

The program will become memory-hungry when the number of random coefficients is increased (assuming micro data are used).  There is a secondary problem that estimating many random coefficients will make estimating those random coefficients accurately more questionable.  Look at the `memsave` option to reduce memory consumption.

## Zero shares

The estimation procedure in [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) offers some robustness to shares that are equal to or very close to zero.  However, that requires that the product level moments are overidentified.

## Efficiency

The estimation procedure in [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) requires an optimal weight matrix for the product level moments (GMM) portion if there is overidentification in the product level moments.  Currently, the algorithm assumes homoskedasticity and independence and produces correct estimates and standard errors under that assumption.  However, to obtain efficiency under those conditions one would have to estimate the error variance $\sigma_\xi^2$ and rerun the algorithm using the estimated $\sigma_\xi^2$ as a weight: see [`DataOptions`](@ref) on how to enter that choice.  Absent homoskedasticity and independence, one can transform the instruments to achieve the same goal.  This is something the use will have to do for herself in the current version of Grumps.  Note that the second stage can be started at the first stage estimates and should not take long to converge (relative to the first stage).

## Floating point numbers

All numbers should be in the same floating point format.  The default (and only heavily tested) format is Float64, i.e. a 64-bit float.  But the code is designed to handle other formats.  This could be attractive if greater precision is desired.  So one could use some form of BigFloat, at the expense of increased memory use and a substantial increase in computation time.

## Nesting of memsave 

If the `memsave` option (see [Optimization options](@ref) and [Memory conservation](@ref)) is set to `true` then Grumps will use some low level code to avoid having to repeatedly allocate and free memory.  What this means is that it is a bad idea to have `grumps!` called from multiple threads simultaneously: from multiple processes should be fine.  If you do not know what this means then you should be ok. 







