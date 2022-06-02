
1. **pml_optimize** in *opt.jl* takes arguments
   * *f* objective function
   * *xstart* starting values (vec of vecs of T)
   * *d* GrumpsData{T}
   * *best* PMLFGH{T}
   * *options*  NTROptions{T}
2.  **grumpsδ!** calls *pml_optimize*.  It takes the following arguments:
    * *InsideObjective!*
    * *fgh* PMLFGH{T} 
    * *θ* 
    * *δstart* vec of vecs of T
    * *e* GrumpsPML
    * *d* GrumpsData{T}
    * *o* OptimizationOptions{T}
    * *s* GrumpsSpace{T}
3.  **InsideObjective!** computes the inside objective function.  It takes the following arguments:
    * *F* FVType{T}
    * *G* GVType{T}
    * *H* HVType{T}
    * *θ* Vec{T}
    * *δ* Vec{Vec{T}}
    * *e* GrumpsPML
    * *d* GrumpsData{T}
    * *o* OptimizationOptions
    * *s* GrumpsSpace{T}
4.  





















