


@todo 3 "currently only saving θ coefficients"
@todo 2 "still need to compute standard errors"
@todo 4 "still need to do penalized estimator"

function SetResult!( sol :: GrumpsSolution{T}, θ :: GType{T}, δ :: GType{T}, β :: GType{T}  ) where {T<:Flt}
    println( θ )
    if θ ≠ nothing
        for i ∈ eachindex( θ )
            sol.θ[i].coef = θ[i]
        end
    end
    if δ ≠ nothing
        for i ∈ eachindex( δ )
            sol.δ[i].coef = δ[i]
        end
    end
    if β ≠ nothing
        for i ∈ eachindex( β )
            sol.β[i].coef = β[i]
        end
    end
    return nothing
end

@todo 2  "SetHighWaterMark! not written yet"
function SetHighWaterMark!( sol :: GrumpsSolution ) 
   
end


function logreport!(sol :: GrumpsSolution, msg :: AbstractString )
    @warn "logreport! not written yet"
end
 
@todo 2 "SetStatus! not written yet"

function SetStatus!( sol :: GrumpsSolution, status :: AbstractString ) 
    
end

@todo 2 "save log and results to file"

const tcritval = 1.9599639845400576



function show( io :: IO, e :: GrumpsEstimate{T}, s :: String = ""; adorned = true, printstde = true, printtstat = true ) where {T<:Flt}
    signif = :normal
    prstyled( adorned, @sprintf( "%+12.6f ", e.coef ) )
    if printstde
        signif = :normal
        if e.stde ≠ nothing && abs( e.coef ) ≥ tcritval * e.stde
            signif = :red
        end
        wtp = "(unavailable ) "
        if e.stde ≠ nothing
            wtp = @sprintf( "(%+12.6f) ", e.stde)
        end
        prstyled( adorned, wtp; color = signif )
    end
    if printtstat
        if e.tstat ≠ nothing 
            signif = :normal
            if abs( e.coef ) ≥ tcritval * e.stde
                signif = :red
            end
            prstyled( adorned, e.tstat ≠ nothing ? @sprintf( "%+12.6f ", e.tstat) : "unavailable  "; color = signif )
        end
    end
    println( e.name  )
    return nothing
end


function show( io :: IO, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; adorned = true, header = false, printstde = true, printtstat = true ) where {T<:Flt}
    header && prstyledln( adorned, "Coefficient estimates for $s: "; bold = true, color = :green )
    for e ∈ est 
        show( io, e, s; adorned = adorned, printstde = printstde, printtstat = printtstat )
    end
    return nothing
end


function show( io :: IO, sol :: GrumpsSolution{T}; adorned = true, printθ = true, printβ = true, printδ = false ) where {T<:Flt}
    prstyledln( adorned, "Coefficient estimates:"; bold = true )
    printθ && show( io, sol.θ, "θ"; header = true  )
    printβ && show( io, sol.β, "β", header = true  )
    printδ && show( io, sol.δ, "δ", header = true  )
    return nothing
end


