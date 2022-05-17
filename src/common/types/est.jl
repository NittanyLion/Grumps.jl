abstract type Estimator end
abstract type GrumpsEstimator <: Estimator end
abstract type GrumpsMLE <: GrumpsEstimator end
abstract type GrumpsPenalized <: GrumpsEstimator end
abstract type GrumpsGMM <: GrumpsEstimator end

@todo 1 "these estimator definitions should be moved to their respective folders"


# set some sensible defaults
usesmicrodata( ::GrumpsEstimator ) = true
usesmacrodata( ::GrumpsEstimator ) = true
usespenalty( ::GrumpsEstimator ) = false
usesmicromoments( ::GrumpsEstimator ) = false

usespenalty( ::GrumpsPenalized ) = true
usespenalty( ::GrumpsGMM ) = true
usespenalty( ::GrumpsMLE ) = false


struct GrumpsMultinomialLogitEstimator <: GrumpsMLE
    function GrumpsMultinomialLogitEstimator() 
        @warn "not yet implemented"
        new()
    end
end

struct GrumpsBLPEstimator <: GrumpsPenalized
    function GrumpsBLPEstimator() 
        @warn "not yet implemented"
        new()
    end
end

struct GrumpsPLMEstimator <: GrumpsPenalized
    function GrumpsPLMEstimator() 
        @warn "not yet implemented"
        new()
    end
end


