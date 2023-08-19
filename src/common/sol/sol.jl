



"""
    SetResult!( sol, θ, δ, β )

Copies the coefficients from the vectors `θ`, `β`, and `δ` to `sol`.  If
any of said vectors is replaced with `nothing` then that vector is not
copied.
"""    
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
    for fld ∈ fieldnames( GrumpsConvergence )
        setfield!( c, fld, getfield( Optim, fld )( r ) )
    end
    return nothing
end

"""
    SetConvergence!( solution, result )

Copies the convergence statistics returned in `result` to the solution `solution`.
"""
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


const tcritval = 1.9599639845400576


"""
    show( io :: IO, e :: GrumpsEstimate{T}, s :: String = ""; keywords...)
    
Show a `GrumpsEstimate` object on `io`; the argument `s` indicates which parameter family (θ,β,δ) the estimate
belongs to.  The optional keywords are described in the table below.

| Keyword      | Description            | Default |
|:-------------|:-----------------------|:--------|
| `adorned`    | make output pretty?    | `true`  |
| `printstde`  | print standard errors? | `true`  |
| `printtstat` | print t statistics?    | `true`  | 
"""
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
            wtp = isnan( e.stde ) ? "  unavailable  " : @sprintf( "(%+12.6f) ", e.stde)
        end
        prstyled( io, adorned, wtp; color = signif )
    end
    if printtstat
        if e.tstat ≠ nothing 
            signif = :normal
            if abs( e.coef ) ≥ tcritval * e.stde
                signif = :red
            end
            prstyled( io, adorned, e.tstat ≠ nothing && !isnan( e.tstat ) ? @sprintf( "%+12.6f ", e.tstat) : "unavailable  "; color = signif )
        end
    end
    println( io, e.name  )
    return nothing
end

"""
    show( io :: IO, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; keywords... )

Shows a vector of estimates on `io` using the string `s` (typically one of θ,β,δ).  The
command takes the following optional keywords.
    
| Keyword      | Description            | Default |
|:-------------|:-----------------------|:--------|
| `adorned`    | make output pretty?    | `true`  |
| `printstde`  | print standard errors? | `true`  |
| `printtstat` | print t statistics?    | `true`  | 
| `header`     | descriptive header?    | `false` |
"""
function show( io :: IO, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; adorned = true, header = false, printstde = true, printtstat = true ) where {T<:Flt}
    header && prstyledln( io, adorned, "Coefficient estimates for $s: "; bold = true, color = :green )
    for e ∈ est 
        show( io, e, s; adorned = adorned, printstde = printstde, printtstat = printtstat )
    end
    return nothing
end

"""
    show( io :: IO, convergence :: GrumpsConvergence{T}; keywords...) 

Shows the contents of `convergence`, where the flags indicated what should be printed and how, as indicated
in the following table.

| Keyword   | Description         | Default |
|:----------|:--------------------|:--------|
| `adorned` | make output pretty? | `true`  |
| `header`  | descriptive header? | `false` |
"""
function show( io :: IO, convergence :: GrumpsConvergence{T}; header = false, adorned = true ) where {T<:Flt }
    header && prstyledln( io, adorned, "Convergence criteria:"; bold = true, color = :green )
    for f ∈ fieldnames( typeof( convergence ) )
        lastonly = occursin( "trace", String( f ) )
        ℓ = lastonly ? " (last)" : ""
        prstyled( io, adorned, @sprintf( "%30s: ", string( f, ℓ ) ); bold = true)
        contents = getfield( convergence, f)
        println( io, lastonly ? ( length( contents) > 0 ? contents[end] : "none" ) : contents )
    end
    return nothing
end

"""
    show( io :: IO, sol :: GrumpsSolution{T}; keywords... ) 

Shows the contents of `sol`, where the keywords indicate what should be printed and how, as
described in the table below.

| Keyword            | Description            | Default |
|:-------------------|:-----------------------|:--------|
| `adorned`          | make output pretty?    | `true`  |
| `printθ`           | print θ results?       | `true`  |
| `printβ`           | print β results?       | `true`  |
| `printδ`           | print δ results?       | `false` |
| `printconvergence` | convergence stats?     | `true`  |
"""
function show( io :: IO, sol :: GrumpsSolution{T}; adorned = true, printθ = true, printβ = true, printδ = false, printconvergence = true ) where {T<:Flt}
    prstyledln( io, adorned, "Coefficient estimates:"; bold = true )
    printθ && show( io, sol.θ, "θ"; header = true  )
    printβ && show( io, sol.β, "β"; header = true  )
    printδ && show( io, sol.δ, "δ"; header = true  )
    printconvergence && show( io, sol.convergence; header = true, adorned = adorned )
    return nothing
end

notnothing( x ) =  isnothing( x ) ? "" : x
notnothingse( x ) =  isnothing( x ) ? "" : "($x)" 

const MimeTex = MIME{Symbol("text/tex")}
const MimeCSV = MIME{Symbol("text/csv")}
const MimeTxt = MIME{Symbol("text/plain")}
const MimeTexCSV = Union{ MimeTex, MimeCSV }
const MimeText = Union{ MimeTex, MimeCSV, MimeTxt }


show( io :: IO, mt::MimeCSV, e :: GrumpsEstimate{T}, s :: String = ""; colsep = "," ) where {T<:Flt} =
    println( io, "$(e.coef)$colsep$(notnothing(e.stde))$colsep$(notnothing(e.tstat))$colsep\"$(e.name)\"" )

show( io :: IO, mt::MimeTex, e :: GrumpsEstimate{T}, s :: String = ""; colsep = "," ) where {T<:Flt} =
    println( io, "$(e.name)&$(notnothing(e.coef))&$(notnothingse(e.stde))\\\\" )


show( io :: IO, mt::MimeTxt, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; colsep = "," ) where {T<:Flt} = show( io, est; adorned = false )
show( io :: IO, mt::MimeTxt, sol :: GrumpsSolution{T}; colsep = "," ) where {T<:Flt} = show( io, sol; adorned = false )

function Grumpsshow( io :: IO, mt, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; colsep = "," ) where {T<:Flt}
    for e ∈ est
        show( io, mt, e, s )
    end
    return nothing
end

show( io :: IO, mt :: MimeTex, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; kwargs... ) where {T<:Flt} =
    Grumpsshow( io, mt, est, s; kwargs... )
show( io :: IO, mt :: MimeCSV, est :: Vector{ GrumpsEstimate{T} }, s :: String = ""; kwargs... ) where {T<:Flt} =
    Grumpsshow( io, mt, est, s; kwargs... )


show( io :: IO, ::MimeCSV, ::Val{:GrumpsHeader}; colsep = "," ) =
    println( io, "estimate$(colsep)stderr$(colsep)tstat$(colsep)variable" )

show( io :: IO, ::MimeTex, ::Val{:GrumpsHeader}; kwargs... ) =
    println( io, "\\begin{tabular}{lrr}\n\\textbf{variable}&\\textbf{coefficient}&\\textbf{(stderr)}\\\\\n\\hline\n")

show( io :: IO, mt :: MimeCSV, ::Val{:GrumpsFooter}; kwargs...) = nothing
show( io :: IO, mt :: MimeTxt, ::Val{:GrumpsFooter}; kwargs...) = nothing
show( io :: IO, ::MimeTex, ::Val{:GrumpsFooter}; colsep = "," ) =
    println( io, "\\end{tabular}\n")




function Grumpsshow( io :: IO, mt, sol :: GrumpsSolution{T}; colsep = ",", printθ = true, printβ = true, printδ = false, printconvergence = true ) where {T<:Flt}
    show( io, mt, Val( :GrumpsHeader ); colsep = colsep )
    printθ && show( io, mt, sol.θ, "θ"; colsep = colsep )
    printβ && show( io, mt, sol.β, "β"; colsep = colsep ) 
    printδ && show( io, mt, sol.δ, "δ"; colsep = colsep )
    show( io, mt, Val( :GrumpsFooter ) )
    return nothing
end

"""
    show( io :: IO, mt :: MIME{Symbol("text/tex")}, sol :: GrumpsSolution; keywords... )

This is the same as [`Save()`](@ref) except that the contents are spit out on io (which could be `stdout` or
an already opened file).
"""
show( io :: IO, mt :: MimeTex, sol :: GrumpsSolution; kwargs... ) = Grumpsshow( io, mt, sol )
"""
    show( io :: IO, mt :: MIME{Symbol("text/csv")}, sol :: GrumpsSolution; keywords... )

This is the same as [`Save()`](@ref) except that the contents are spit out on io (which could be `stdout` or
an already opened file).
"""
show( io :: IO, mt :: MimeCSV, sol :: GrumpsSolution; kwargs... ) = Grumpsshow( io, mt, sol; kwargs... )



const mimematch = [ 
    ( [".csv"], "text/csv" ),
    # ( [".html", "htm"], "text/html" ),
    ( [".tex"], "text/tex" ),
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

"""
    Save( fn, mt, sol :: GrumpsSolution; keywords... )

Saves the solution stored in `sol` to a file with filename `fn` which has mime type `mt`.  

There are several keywords that are described below, some of which will be ignored for
some mime types.  Allowed mime types are `text/plain`, `text/csv`, and `text/tex`.

| Keyword            | Description            | Default |
|:-------------------|:-----------------------|:--------|
| `colsep`           | column separator       | `","`   |
| `adorned`          | make output pretty?    | `true`  |
| `printθ`           | print θ results?       | `true`  |
| `printβ`           | print β results?       | `true`  |
| `printδ`           | print δ results?       | `false` |
| `printconvergence` | convergence stats?     | `true`  |
"""
function Save( fn :: AbstractString, mt :: MimeText, x :: Any; kwargs... )
    open( fn, "w" ) do fl
        show( fl, mt, x; kwargs... )
    end
    return nothing
end

"""
    Save( fn, sol :: GrumpsSolution; keywords... )

The same as the form of `Save` with prespecified mime type except that the mime type is now inferred from
the file extension.  The keywords also have the same meaning, namely...

There are several keywords that are described below, some of which will be ignored for
some mime types.  Allowed mime types are `text/plain`, `text/csv`, and `text/tex`.

| Keyword            | Description            | Default |
|:-------------------|:-----------------------|:--------|
| `colsep`           | column separator       | `","`   |
| `adorned`          | make output pretty?    | `true`  |
| `printθ`           | print θ results?       | `true`  |
| `printβ`           | print β results?       | `true`  |
| `printδ`           | print δ results?       | `false` |
| `printconvergence` | convergence stats?     | `true`  |
"""
function Save( fn :: AbstractString, x :: Any; kwargs... )
    return Save( fn, infermimetype( fn ), x; kwargs... )
end

