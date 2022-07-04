abstract type Estimator end
abstract type GrumpsEstimator <: Estimator end
abstract type GrumpsMLE <: GrumpsEstimator end
abstract type GrumpsPenalized <: GrumpsEstimator end
abstract type GrumpsGMM <: GrumpsEstimator end



# set some sensible defaults
usesmicrodata( ::GrumpsEstimator ) = true
usesmacrodata( ::GrumpsEstimator ) = true
usespenalty( ::GrumpsEstimator ) = false
usesmicromoments( ::GrumpsEstimator ) = false

usespenalty( ::GrumpsPenalized ) = true
usespenalty( ::GrumpsGMM ) = true
usespenalty( ::GrumpsMLE ) = false

seprocedure( ::GrumpsEstimator ) = :defaultseprocedure
seprocedure( ::GrumpsGMM ) = :notyetimplemented

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


