


const RCColor = Crayon( reset=true, foreground = 128, bold = true )
const zColor = Crayon( reset=true, foreground = :red, bold = true )
const xColor = Crayon( reset=true, foreground = :green, bold = true  )
const OpColor = Crayon( reset=true, foreground = :blue, bold = true )
const CfColor = Crayon( reset=true, bold = true )
const EnColor = Crayon( reset=true, foreground = :yellow, bold = true )
const NumColor = Crayon( reset=true, foreground = :green, bold = true )
const HeadColor = Crayon( reset = true, bold = true )
const EstColor = Crayon( reset=true, foreground = :magenta, bold = true )
const EmColor = Crayon( reset=true, foreground = :yellow,  bold = true )
const MathColor = Crayon( reset=true, foreground = 123, bold = true )
const AlertColor = Crayon( reset=true, foreground = :red, blink = true, bold = true )
const IgnoreColor = Crayon( reset=true, foreground = 247, bold = false)
const Reset = Crayon( reset = true )





function Suffix( i :: Int )
    j = i % 10
    sfx = "$(Char( 8320 + j ))"
    i < 10 && return sfx
    return Suffix( div( i - j, 10 ) ) * sfx
end

function PrintCoefficient( io, vr :: String, i :: Int ) 
    print( io, CfColor, " $vr" * Suffix( i ), Reset )
    return nothing   
end


function PrintThetaName( io, s :: AbstractString, rcs )
    ss = split( s, "*" )
    if length( ss ) == 2
        print( io, zColor, strip( ss[1] ), "ᵢₘ", Reset )
    else
        ss = split( s, "rc on" )
        if length( ss ) < 2
            print( io, zColor, strip( s ), "ᵢₘ", Reset )
            return rcs
        end
        rcs += 1
        print( io, RCColor, "ν", "ᵢ", Suffix( rcs ), "ₘ", Reset )
    end
    print( io, xColor , strip( ss[2] ), "ⱼₘ", Reset ) 
    return rcs
end


function IsEndogenous( s, instruments )
    ff = findfirst( x -> x == String( s ), instruments )
    ff ≠ nothing && return false, s 
    oi = occursin( "dum_", s )
    oi || return true, s 
    return false, s[5:end]
end



function PrintBetaName( io, s :: AbstractString, instruments :: Vec{ String } ) 
    s == "constant" && return
    ise, ss = IsEndogenous( s, instruments )
    clr = ise ? EnColor : xColor
    return print( io, clr, ss, "ⱼₘ", Reset )
end

function UtilityString( d :: GrumpsData )
    io = IOBuffer()
    print( io, RCColor, "Uᵢⱼₘ ", OpColor, "=", Reset )
    nm = names( d )
    rcs = 0
    for t ∈ eachindex( nm.θnames )
        print( io, OpColor, (t > 1 ? " +" : " " ), Reset )
        PrintCoefficient( io, "θ", t ) 
        rcs += PrintThetaName( io, strip( nm.θnames[t] ), rcs )
    end
    for t ∈ eachindex( nm.βnames )
        print( io, OpColor, " +" , Reset )
        PrintCoefficient( io, "β", t ) 
        PrintBetaName( io, strip( nm.βnames[t] ), nm.bnames )
    end
    print( io, OpColor, " +", RCColor, " ξⱼₘ", Reset )
    print( io, OpColor, " +", RCColor, " ϵᵢⱼₘ", Reset )
    return String( take!( io ) ) 
end


function InstrumentsString( d :: GrumpsData )
    io = IOBuffer()
    nm = names( d )
    print( io, OpColor, "instruments: " )
    regs = String.( strip.( nm.βnames ) )
    first = true
    for bn ∈ strip.( nm.bnames )
        bn ∈ regs && continue
        first || print( io, ", " )
        first = false
        print( io, bn )
    end
    print( Reset )
    return String( take!( io ) ) 
end

function PrettyInt( i :: Int )
    j = i % 1000
    i < 1000 && return string( j )
    r = div( i - j, 1000 )
    return PrettyInt( r ) * ',' * lpad( j, 3, '0' )
end

function Sizes( d :: GrumpsData )
    S = sum( dimS( d ) )
    J = sum( dimJ( d ) )
    M = sum( dimM( d ) )
    N = Int( round( sum( dimN( d ) ) ) ) 
    dθz = dimθz( d )
    dθν = dimθν( d )
    dβ = dimβ( d )
    db = dimmom( d )
    io = IOBuffer( )
    for pr ∈ [ (M, " markets; "), ( J, " products; "), ( N, " consumers; " ), ( S, " micro consumers; "), ( dθz, " interactions; " ), ( dθν, " random coefficients; " ), ( dβ, " product regressors; " ), ( db, " instruments" ) ]
        print( io, NumColor, PrettyInt( pr[1] ), Reset, pr[2] )
    end    
    return String( take!( io ) ) 
end

function IntegrationSizes( d :: GrumpsData )
    Rmic = sum( dimRmic( d ) )
    Rmac = sum( dimRmac( d ) )
    io = IOBuffer( )
    for pr ∈ [ (Rmic, " micro nodes/draws; "), ( Rmac, " macro nodes/draws ") ]
        print( io, NumColor, PrettyInt( pr[1] ), Reset, pr[2] )
    end    
    return String( take!( io ) ) 
end



function HeadPrint( s, marker =  '―')
    left = div( 78 - textwidth( s ), 2 )
    right = 78 - left - textwidth( s ) 
    print( HeadColor, marker^left, " $s ", marker^right,Reset, "\n" )
end

TailPrint( s ) = HeadPrint( s, '∧' )


function PrettyScientific( x )
    x ≈ 0.0 && return @sprintf( "%10d ", 0 )
    y = log10( x )
    isapprox( y, round( y ) ) && return @sprintf( "%10s ", "1e$(Int(y))" )
    return @sprintf( "%10f ", x )
end

ToleranceOneLiner( vr, o, maxrepeats = -1 ) = println( @sprintf( "%10s ", vr ), PrettyScientific.( [ o.f_tol; o.g_tol; o.x_tol ] )..., i10( o.iterations ), maxrepeats ≥ 0 ? i10( maxrepeats ) : " "  )

s10( s :: AbstractString ) =  @sprintf("%10s ", s )
i10( i :: Int ) = @sprintf( "%10d ", i  )

function ToleranceDescription( o :: OptimizationOptions )
    println( EmColor, "tolerances ", HeadColor, s10.( ["f_tol"; "g_tol"; "x_tol"; "iterations"; "maxrepeats" ] )..., Reset )
    ToleranceOneLiner( "δ", o.δ )
    ToleranceOneLiner( "θ", o.θ, o.maxrepeats )
end




function emphornot( cond, val )
    io = IOBuffer()
    print( io, cond ? AlertColor : Reset, val, Reset )
    return String( take!( io ) ) 
end

function deemphornot( cond, val )
    io = IOBuffer()
    print( io, cond ? IgnoreColor : Reset, val, Reset )
    return String( take!( io ) ) 
end




function PrintThreads( th :: GrumpsThreads, memsave )
    println( EmColor, "threads     ", HeadColor, s10.( [ "machcpus"; "machthr"; "specthr"; "blasthr"; "mktthr"; "inthr" ] )..., Reset )
    println( "            ",  i10.( [ cpucores(); cputhreads() ] )..., 
        emphornot( nthreads() < cpucores(), i10( nthreads() ) ),
        emphornot( BLAS.get_num_threads() < cpucores(), i10( BLAS.get_num_threads() ) ), 
        deemphornot( !memsave, i10( mktthreads( th ) ) ),
        deemphornot( true, i10( inthreads(th) ) ) ) 
end

function PrintStructure( e :: Estimator, d :: GrumpsData,  o :: OptimizationOptions, θstart, seo :: StandardErrorOptions ) 
    println()
    HeadPrint( "Summary", '∨' )
    HeadPrint( "Specification")
    println( UtilityString( d ) )
    println( InstrumentsString( d ) )
    HeadPrint( "Data Sizes" )
    println(  Sizes( d ) )
    HeadPrint( "Detailed Estimator Description" )
    println( DetailedDescription( e ) )
    HeadPrint( "Nodes and Draws" )
    println( IntegrationSizes( d ) )
    HeadPrint( "Optimization Options" )
    ToleranceDescription( o ) 
    PrintThreads( o.gth, o.memsave )
    println( EmColor, "loop vectorization ", Reset,  emphornot( !o.loopvectorization, o.loopvectorization ) )
    HeadPrint( "Memory Conservation" )
    println( EmColor, "memsave ", Reset, o.memsave )
    # HeadPrint( "Replicability" )
    # println( EmColor, "Replicable", Reset, " = ", ")
    TailPrint( "End of Summary" )
    println()
    return nothing
end


