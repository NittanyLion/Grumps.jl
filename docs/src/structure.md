# Directory structure

There are really two folders with sources:
* *src* for the programs
* *docs* for the documentation

Within *src* you will find the main package file *Grumps.jl* and *includes.jl*, which loads all source code.

Beyond that, you will find several folders:
* *packages*: loads all packages
* *common*: loads code that is common to several estimators
* code that is specific to one estimator, one folder per estimator

If you want to see how a particular data type is defined, just check out the *types* folder.  Since there are many types and subtypes, it can be handy to type *GrumpsTypes()* to get a list of some of the major ones.

If you wish to learn more about the algorithm itself, head to the *optim* folder.