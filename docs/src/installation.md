# Installation and invocation


First, ensure that you have Julia version 1.8 or later installed.  Julia can be downloaded from [Julia downloads page](https://julialang.org/downloads/).  Grumps will *not* work with older versions of Julia.




## Installation

Package installation is achieved in the usual way, i.e. by typing 
```
	]add Grumps
```
in the Julia  REPL.  

!!! note "For those unfamiliar with Julia:" 
	The REPL is the environment that opens up if you start Julia without arguments or which you automatically get with virtual studio code, the preferred editor for Julia.

	So once you have started Julia, type the character `]`: this will open the packaging system for you.  Then type `add Grumps`; this will install Grumps.  Finally, hit the backspace key to take yourself out of the packaging system again.

## Invocation

Fire up Julia using `julia -t 4` replacing the number 4 with whatever number of threads you wish to use (or `auto` to automatically use all threads in your computer).  The recommended number is the number of physical cores in your computer, which is usually less than the total number of threads (often by a factor of two).  As a permanent solution, one can set the `JULIA_NUM_THREADS` environment variable.

Grumps can then be loaded with `using Grumps`.  That's it: you're ready to go.
