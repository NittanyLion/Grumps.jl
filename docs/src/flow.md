# Algorithm flow

When Grumps is called using the *grumps* function, it runs *est.jl* in the *optim* folder.  This sets up various objects and then calls an optimizer with an objective function that is estimator-specific.  In other words, it will call a different method depending on the *e* argument in *ObjectiveFunctionθ!* in *est.jl* in the *optim* folder.

These methods *ObjectiveFunctionθ!* are defined either in one of the julia files in the *optim* folder whose name starts with obj, or in a specific estimator folder.  *ObjectiveFunctionθ!* then decides which internal optimizer (i.e. one that finds $δ$) to call: they're all called *grumpsδ!*.
