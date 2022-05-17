

abstract type GrumpsVersion end

struct GrumpsVersionMLE <: GrumpsVersion 
end


struct GrumpsVersionPenalty <: GrumpsVersion
    σ2      :: Float64
end


struct GrumpsVersionNone    <: GrumpsVersion
end 

struct GrumpsVersionGMM     <: GrumpsVersion
end
