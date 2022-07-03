# Installation and invocation


First, ensure that you have Julia version 1.8 or later installed.  Julia can be downloaded from [Julia downloads page](https://julialang.org/downloads/).  Grumps will *not* work with older versions of Julia.

*There are two sets of explanation below.  The first bit covers how to install Grumps before it is included in the Julia package system.  This is more cumbersome and will not be needed in the future.*

## For now

### Installation

First pull the main branch of Grumps from Github.  Then install all required packages by running the code in `temp/installrequiredpackages.jl`.  That is all that is needed for installation.

### Invocation


Fire up Julia using *julia -t 4* replacing the number 4 with whatever number of threads you wish to use.  The recommended number is the number of physical cores in your computer.  As a permanent solution, one can set the `JULIA_NUM_THREADS` environment variable.

Then type:
```
    push!( LOAD_PATH, "*wherever Grumps.jl/src is located*" )
    using Grumps
```

Now you're good to go.  You can alternatively invoke Julia from the command line with the name of the file containing your code, which should have the above two lines at the top.

Please do not try to install or invoke Grumps any other way until it is in the Julia package ecosystem.



## Once Grumps is in the Julia package ecosystem



### Installation

Package installation is achieved in the usual way, i.e. by typing *]add Grumps* in REPL.

### Invocation

Fire up Julia using *julia -t 4* replacing the number 4 with whatever number of threads you wish to use.  The recommended number is the number of physical cores in your computer.  As a permanent solution, one can set the `JULIA_NUM_THREADS` environment variable.

Grumps can then be loaded with `using Grumps`.  That's it: you're ready to go.
