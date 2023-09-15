# Package versions


## 0.2.0

Adds:

* user-defined interactions; see [User-specified interactions](@ref)
* loop vectorization, which increases speed by an order of magnitude
* intra-iteration progress bar; see [`OptimizationOptions()`](@ref)
* greater type stability, which cuts down on compilation time
* precomputed quadrature nodes
  

## 0.2.1

* addressed Mac progress bar infelicity
* turned off progress bar by default


## 0.2.2

* Added compatibility checks
* Precautionary change to improve robustness across operating systems

## 0.2.3

1. Bug fix for the case in which there are no macro data but an estimator other than mixed logit is selected.

## 0.2.4

1. Bug fix for the user-specified arbitrary interactions case.