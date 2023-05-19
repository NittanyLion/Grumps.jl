# Directory structure

## Top level folders

There are really two folders with sources:
* `src` for the programs
* `docs` for the documentation

## src folder

Grumps is open source.  If you clone the repository at [the github site](https://github.com/NittanyLion/Grumps.jl) you will have accesss to the full directory tree.

Within `src` you will find the main package file `Grumps.jl` plus `includes.jl`, which loads all source code, and `exports.jl` which contains all exported symbols, i.e. symbols that you can use directly in your program without prefacing it with `Grumps.`.

Beyond that, you will find several folders in `src`:
* `packages`: loads all packages
* `common`: loads code that is common to several estimators
* `estimators`: code that is specific to one estimator
* `integrators`: code that is specific to one integrator

## common folder

Within `common` there are a number of folders depending on the role they play in the program.  These are listed below.  
* `array` utilities for dealing with arrays
* `data` data handling
* `early` code that should be read and processed before other code
* `error` error handling
* `est` code that gets called to compute estimators
* `imports` imports from other packages, mostly `Base`
* `inference` standard errors and such
* `integration` numerical integration
* `io` reading data from and to files
* `optim` optimization
* `probs` computation of choice probabilities
* `sol` handling solution object
* `space` dealing with objects that reserve space ahead of time
* `threads` multithreading objects
* `tree` contains code to print object types
* `types` contains code that defines object types
* `utils` contains miscellaneous utilities

## estimators folder

The `estimators` folder contains a number of folders, one per estimator.  Each folder corresponds to a specific estimator.  For instance, `cler` contains code specific to the main Grumps estimator.

## integrators folder

The `integrators` folder contains folders, one per integration method, for any integrators beyond the default integrators, which are handled under `common`.

