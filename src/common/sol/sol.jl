


@todo 3 "currently only saving θ coefficients"
@todo 2 "still need to compute standard errors"
@todo 4 "still need to do penalized estimator"

function SetResult!( sol :: GrumpsSolution{T}, θ :: GType{T}, δ :: GType{T}, β :: GType{T}  ) where {T<:Flt}
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


function SetConvergence!( c :: GrumpsConvergence{T}, r ) where {T<:Flt}
    c.minimum = minimum( r )
    c.iterations = Optim.iterations( r )
    c.iteration_limit_reached = Optim.iteration_limit_reached( r )
    c.converged = Optim.converged( r )
    c.f_converged = Optim.f_converged( r )
    c.g_converged = Optim.g_converged( r )
    c.x_converged = Optim.x_converged( r )
    c.f_calls = Optim.f_calls( r )
    c.g_calls = Optim.g_calls( r )
    c.h_calls = Optim.h_calls( r )
    return nothing
end

SetConvergence!( sol :: GrumpsSolution, res ) = SetConvergence!( sol.convergence, res )

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
    prstyled( io, adorned, @sprintf( "%+12.6f ", e.coef ) )
    if printstde
        signif = :normal
        if e.stde ≠ nothing && abs( e.coef ) ≥ tcritval * e.stde
            signif = :red
        end
        wtp = "(unavailable ) "
        if e.stde ≠ nothing
            wtp = @sprintf( "(%+12.6f) ", e.stde)
        end
        prstyled( io, adorned, wtp; color = signif )
    end
    if printtstat
        if e.tstat ≠ nothing 
            signif = :normal
            if abs( e.coef ) ≥ tcritval * e.stde
                signif = :red
            end
            prstyled( io, adorned, e.tstat ≠ nothing ? @sprintf( "%+12.6f ", e.tstat) : "unavailable  "; color = signif )
        end
    end
    println( io, e.name  )
    return nothing
end


function show( io :: IO, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; adorned = true, header = false, printstde = true, printtstat = true ) where {T<:Flt}
    header && prstyledln( io, adorned, "Coefficient estimates for $s: "; bold = true, color = :green )
    for e ∈ est 
        show( io, e, s; adorned = adorned, printstde = printstde, printtstat = printtstat )
    end
    return nothing
end


function show( io :: IO, convergence :: GrumpsConvergence{T}; header = false, adorned = true ) where {T<:Flt }
    header && prstyledln( io, adorned, "Convergence criteria:"; bold = true, color = :green )
    for f ∈ fieldnames( typeof( convergence ) )
        prstyled( io, adorned, @sprintf( "%30s: ", f ); bold = true)
        println( io, getfield( convergence, f) )
    end
    return nothing
end

function show( io :: IO, sol :: GrumpsSolution{T}; adorned = true, printθ = true, printβ = true, printδ = false, printconvergence = true ) where {T<:Flt}
    prstyledln( io, adorned, "Coefficient estimates:"; bold = true )
    printθ && show( io, sol.θ, "θ"; header = true  )
    printβ && show( io, sol.β, "β"; header = true  )
    printδ && show( io, sol.δ, "δ"; header = true  )
    printconvergence && show( io, sol.convergence; header = true, adorned = adorned )
    return nothing
end

notnothing( x ) =  isnothing( x ) ? "" : x

function show( io :: IO, mt::MIME{Symbol("text/csv")}, e :: GrumpsEstimate{T}, s :: String = ""; colsep = "," ) where {T<:Flt}
    println( io, "$(e.coef)$colsep$(notnothing(e.stde))$colsep$(notnothing(e.tstat))$colsep\"$(e.name)\"" )
    return nothing
end

show( io :: IO, mt::MIME{Symbol("text/plain")}, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; colsep = "," ) where {T<:Flt} = show( io, est; adorned = false )
show( io :: IO, mt::MIME{Symbol("text/plain")}, sol :: GrumpsSolution{T}; colsep = "," ) where {T<:Flt} = show( io, sol; adorned = false )

function show( io :: IO, mt::MIME{Symbol("text/csv")}, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; colsep = "," ) where {T<:Flt}
    for e ∈ est
        show( io, mt, e, s )
    end
    return nothing
end

function show( io :: IO, mt::MIME{Symbol("text/csv")}, ::Val{:GrumpsCSVHeader}; colsep = "," )
    print( io, "estimate$(colsep)stderr$(colsep)tstat$(colsep)variable\n" )
end

function show( io :: IO, mt::MIME{Symbol("text/csv")}, sol :: GrumpsSolution{T}; colsep = "," ) where {T<:Flt}
    show( io, mt, Val( :GrumpsCSVHeader ); colsep = colsep )
    show( io, mt, sol.θ, "θ"; colsep = colsep )
    show( io, mt, sol.β, "β"; colsep = colsep ) 
    show( io, mt, sol.δ, "δ"; colsep = colsep )
    return nothing
end


function Save( fn :: AbstractString, mt :: MIME{}, x :: Any; colsep = "," )
    open( fn, "w" ) do fl
        show( fl, mt, x; colsep = colsep )
    end
    return nothing
end


const mimematch = [ 
    ( [".csv"], "text/csv" ),
    # ( [".html", "htm"], "text/html" ),
    # ( [".tex"], "text/tex" ),
    ( [".txt"], "text/plain" )
]

function infermimetype( fn :: AbstractString )
    ext = lowercase( splitext( fn )[2] )
    @warnif length( ext ) < 2 "need a file extension to infer file type; no file saved"
    for m ∈ mimematch
        ext ∈ m[1] && return MIME( m[2] )
    end
    @warn "unknown extension $ext; guessing text/plain mime type"
    return MIME("text/plain")
end


function Save( fn :: AbstractString, x :: Any; colsep = "," )
    return Save( fn, infermimetype( fn ), x; colsep = colsep )
end

