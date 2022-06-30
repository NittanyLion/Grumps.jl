# Installation and invocation


*Parts of the explanation below applies once Grumps has been included into the Julia ecosystem*

## Installation

Package installation is achieved in the usual way, i.e. by typing *]add Grumps* in REPL.

## Invocation

Fire up Julia using *julia -t 4* replacing the number 4 with whatever number of threads you wish to use.  The recommended number is the number of physical cores in your computer.  As a permanent solution, one can set the `JULIA_NUM_THREADS` environment variable.

Grumps can then be loaded with *using Grumps*.  That's it: you're ready to go.
