

abstract type GrumpsVersion end

struct GrumpsVersionMLE <: GrumpsVersion 
end


struct GrumpsVersionPenalty <: GrumpsVersion
end


struct GrumpsVersionNone    <: GrumpsVersion
end 

struct GrumpsVersionGMM     <: GrumpsVersion
end
