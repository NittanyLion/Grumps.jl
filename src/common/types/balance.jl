struct GrumpsNormalization{T<:Flt}
    μ   :: T
    σ   :: T

    function GrumpsNormalization( μ :: T2, σ :: T2 ) where {T2<:Flt}
        @ensure σ > zero( T2 )  "standard deviation should be positive"
        new{T2}( μ, σ )
    end
end


function show( io :: IO, n :: GrumpsNormalization{T}; adorned = true ) where {T<:Flt}
    prstyledln( adorned, "GrumpsNormalization  $(n.μ) $(n.σ)"; color = :green, bold = true )
    return nothing 
end
    

