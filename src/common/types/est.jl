abstract type Estimator end
abstract type GrumpsEstimator <: Estimator end
abstract type GrumpsMLE <: GrumpsEstimator end
abstract type GrumpsPenalized <: GrumpsEstimator end
abstract type GrumpsGMM <: GrumpsEstimator end

const GrumpsEstimatorClasses = [ GrumpsMLE; GrumpsPenalized; GrumpsGMM ]

# set some sensible defaults
usesmicrodata( ::GrumpsEstimator ) = true
usesmacrodata( ::GrumpsEstimator ) = true
usespenalty( ::GrumpsEstimator ) = false
usesmicromoments( ::GrumpsEstimator ) = false
iopattern( ::GrumpsEstimator) = "000000"

usespenalty( ::GrumpsPenalized ) = true
usespenalty( ::GrumpsGMM ) = true
usespenalty( ::GrumpsMLE ) = false

seprocedure( ::GrumpsEstimator ) = :defaultseprocedure
seprocedure( ::GrumpsGMM ) = :notyetimplemented

struct GrumpsMultinomialLogitEstimator <: GrumpsMLE
    function GrumpsMultinomialLogitEstimator() 
        @ensure false "GrumpsMultinomialLogitEstimator not yet implemented"
        new()
    end
end

struct GrumpsBLPEstimator <: GrumpsPenalized
    function GrumpsBLPEstimator() 
        @ensure false "GrumpsBLPEstimator not yet implemented"
        new()
    end
end


struct EstimatorDescription
    symbol          :: Symbol
    name            :: String
    descriptions    :: Vector{String}
end

