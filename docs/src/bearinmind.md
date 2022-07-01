# Things to bear in mind

## Starting values

The global objective function is convex in $\delta$, so convergence of the inner optimization is generally uneventful.  Although the objective function is not convex in $\theta$, the outer optimization often achieves the (near) optimum from a single starting value.  However, this is not guaranteed.  

The most frequent case in which this would go wrong is when one or more of the $\theta^\nu$ coefficients goes to zero and gets stuck.  This is more likely to happen when there are identification problems, e.g. when $\theta^z \approx 0$ and the product level moments do not provide much identifying power.  Just try a few other starting values.

## Number of random coefficients

The program will become memory-hungry when the number of random coefficients is increased (assuming micro data are used).  There is a secondary problem that estimating many random coefficients will make estimating those random coefficients accurately more questionable.  Look at the `memsave` option to reduce memory consumption.

## Zero shares

The estimation procedure in [Grieco, Murry, Pinkse, and Sagl (2022)](http://joris.pinkse.org/paper/grumps/) offers some robustness to shares that are equal to or very close to zero.  However, that requires that the product level moments are overidentified.

