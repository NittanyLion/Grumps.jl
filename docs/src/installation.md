# Installation and invocation


First, ensure that you have Julia version 1.8 or later installed.  Julia can be downloaded from [Julia downloads page](https://julialang.org/downloads/).  Grumps will *not* work with older versions of Julia.

*There are two sets of explanation below.  The first bit covers how to install Grumps before it is included in the Julia package system.  This is more cumbersome and will not be needed in the future.*

## For now

### Installation

First pull the main branch of Grumps from Github.  Then install all required packages by running the code in `temp/installrequiredpackages.jl`.  That is all that is needed for installation.

### Invocation


Fire up Julia using `julia -t 4` replacing the number 4 with whatever number of threads you wish to use (or `auto` to automatically use all threads in your computer).  The recommended number is the number of physical cores in your computer, which is usually less than the total number of threads (often by a factor of two).  As a permanent solution, one can set the `JULIA_NUM_THREADS` environment variable.

Then type:
```
    push!( LOAD_PATH, "*wherever Grumps.jl/src is located*" )
    using Grumps
```

Now you're good to go.  You can alternatively invoke Julia from the command line with the name of the file containing your code, which should have the above two lines at the top.

In lieu of specifying `LOAD_PATH` on every call, one can set the `JULIA_LOAD_PATH` environment variable in one's operating system.

Please do not try to install or invoke Grumps any other way until it is in the Julia package ecosystem.



## Once Grumps is in the Julia package ecosystem



### Installation

Package installation is achieved in the usual way, i.e. by typing 
```
	]add Grumps
```
in the Julia  REPL.  

!!! note "For those unfamiliar with Julia:" 
	The REPL is the environment that opens up if you start Julia without arguments or which you automatically get with virtual studio code, the preferred editor for Julia.

	So once you have started Julia, type the character `]`: this will open the packaging system for you.  Then type `add Grumps`; this will install Grumps.  Finally, hit the backspace key to take yourself out of the packaging system again.

### Invocation

Fire up Julia using `julia -t 4` replacing the number 4 with whatever number of threads you wish to use (or `auto` to automatically use all threads in your computer).  The recommended number is the number of physical cores in your computer, which is usually less than the total number of threads (often by a factor of two).  As a permanent solution, one can set the `JULIA_NUM_THREADS` environment variable.

Grumps can then be loaded with `using Grumps`.  That's it: you're ready to go.
