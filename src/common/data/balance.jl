# The functions below deal with balancing of the data.
# This refers to scaling the data before optimizing.
# Unbalancing then reverses this action.



function computeμσ( μ :: T, σ :: T, count :: Int ) where {T<:Flt}
    μ /= count
    σ = σ / count - μ^2 
    σ = σ > sqrt( eps( T ) ) ? sqrt( σ ) : zero( T )  
    μ, σ
end


function BalanceZConstants( md :: Union{ GrumpsMicroDataAnt, GrumpsMicroDataHog, MSMMicroDataHog }, t :: Int )
    J = size( md.Z, 2 )
    insides = 1:J-1
    S = size( md.Z, 1 )
    return sum( md.Z[:, insides, t ] ), sum( md.Z[:, insides, t ].^2 ), (J-1) * S
end

function BalanceZConstants( md :: MicroData, t :: Int )
    @ensure false "Type $(typeof(md)) not yet implemented"
end

function BalanceXConstants( md :: GrumpsMicroDataHog, t :: Int )
    R, J, dθν = size( md.X )
    @ensure 1 ≤ t ≤ dθν "there are fewer than $t random coefficients, namely $dθν"
    insides = 1:J-1
    return sum( md.X[:, insides, t ] ), sum( md.X[:, insides, t ].^2 ), (J-1) * R
end

function BalanceXConstants( md :: GrumpsMicroDataAnt, t :: Int )
    J, dθν = size( md.𝒳 )
    R = size( md.𝒟, 1 )
    @ensure 1 ≤ t ≤ dθν "there are fewer than $t random coefficients, namely $dθν"
    insides = 1:J-1
    return sum( md.𝒳[ j, t ] * md.𝒟[ r, t ] for j ∈ insides, r ∈ 1:R ), sum( ( md.𝒳[ j, t ] * md.𝒟[ r,t ] )^2 for j ∈ insides, r ∈ 1:R ), (J-1) * R
end

function BalanceXConstants( md :: MSMMicroDataHog, t :: Int )
    R, S, J, dθν = size( md.X )
    @ensure 1 ≤ t ≤ dθν "there are fewer than $t random coefficients, namely $dθν"
    insides = 1:J-1
    return sum( md.X[:,:, insides, t ] ), sum( md.X[:,:, insides, t ].^2 ), (J-1) * R * size( md.X, 2 )
end

function BalanceXConstants( md, t :: Int )
    @ensure false "balancing random coefficients is not yet implemented for $(typeof(md))"
end


function Balance!( md :: GrumpsMicroDataHog{T} , t :: Int, σ :: T ) where {T<:Flt}
    md.X[:,:,t] ./= σ
    return nothing
end

function Balance!( md :: GrumpsMicroDataAnt{T} , t :: Int, σ :: T ) where {T<:Flt}
    md.𝒳[:,t] ./= σ
    return nothing
end


function Balance!( md :: MSMMicroDataHog{T} , t :: Int, σ :: T ) where {T<:Flt}
    md.X[:,:,:,t] ./= σ
    return nothing
end


Balance!( Md :: GrumpsMacroNoData, t :: Int, σ :: T ) where {T<:Flt }= nothing

function Balance!( Md, t :: Int, σ :: T ) where {T<:Flt}
    @ensure false "balancing not yet implemented for $(typeof(Md))"
end

function Balance!( Md :: GrumpsMacroDataHog{T}, t :: Int, σ :: T ) where {T<:Flt}
    Md.A[:,:,t] ./= σ
    return nothing
end

function Balance!( Md :: GrumpsMacroDataAnt{T}, t :: Int, σ :: T ) where {T<:Flt}
    Md.𝒳[:,t] ./= σ
    return nothing
end


function Balance!( gd :: GrumpsData{T}, scheme :: Val{ :micro } ) where {T<:Flt}
   
    dθ = length( gd.balance )
    activemarkets = findall( x->!( typeof(x.microdata) <: GrumpsMicroNoData ), gd.marketdata )
    dθz = size( gd.marketdata[activemarkets[1]].microdata.Z, 3 ) :: Int
    # normalize interactions
    @threads for t ∈ 1:dθz
        μ = σ = zero( T )
        count = 0
        for m ∈ activemarkets
            local μadd, σadd, countadd = BalanceZConstants( gd.marketdata[m].microdata, t )
            μ += μadd;  σ += σadd; count += countadd
        end
        @ensure count > 1  "need more than one consumer to balance"
        μ, σ = computeμσ( μ, σ, count )
        if σ > zero( T )
            for m ∈ activemarkets
                gd.marketdata[m].microdata.Z[:,:,t] ./= σ
            end
        end
        gd.balance[t] = GrumpsNormalization( μ, σ )
    end
    # normalize random coefficients
    @threads for k ∈ dθz + 1 : dθ
        t = k - dθz
        μ = σ = zero( T )
        count = 0
        for m ∈ activemarkets
            local μadd, σadd, countadd = BalanceXConstants( gd.marketdata[m].microdata, t )
            μ += μadd;  σ += σadd; count += countadd
        end
        @ensure count > 1  "need more than one consumer to balance"
        μ, σ = computeμσ( μ, σ, count )
        if σ > zero( T )
            for m ∈ activemarkets
                Balance!( gd.marketdata[m].microdata, t, σ )
            end
        end
        gd.balance[k] = GrumpsNormalization( μ, σ )
    end
    # now rescale the macro end
    @threads :dynamic for t ∈ 1:dθ
        for m ∈ eachindex( gd.marketdata )
            Balance!( gd.marketdata[m].macrodata, t, gd.balance[t].σ )
        end
    end
    return nothing
 end


function Balance!( gd :: GrumpsData{T}, :: Val{ :macro }  ) where {T<:Flt}
    @ensure false "Macro balance not yet implemented"
end


function Balance!( gd :: GrumpsData{T}, scheme :: Val{ :none } ) where {T<:Flt}
    for t ∈ eachindex( gd.balance )
        gd.balance[t] = GrumpsNormalization( zero(T), one(T) )
    end
    return nothing
end


function Unbalance!( θ :: Vector{T}, gd :: GrumpsData{T} ) where {T<:Flt}
    for t ∈ eachindex( gd.balance )
        θ[t] /= gd.balance[t].σ
    end
    return nothing
end


function Unbalance!( fgh :: GrumpsSingleFGH{T}, gd :: GrumpsData{T} ) where {T<:Flt}
    for t ∈ 1:dimθ( gd )
        fgh.Gθ[t] *= gd.balance[t].σ
        fgh.Hθθ[t,:] *= gd.balance[t].σ
        fgh.Hθθ[:,t] *= gd.balance[t].σ
        fgh.Hδθ[:,t] *= gd.balance[t].σ
    end
    return nothing
end

function Unbalance!( fgh :: MarketFGH{T}, gd :: GrumpsData{T} ) where {T<:Flt}
    fgh.inside === fgh.outside || Unbalance!( fgh.outside, gd )
    return Unbalance!( fgh.inside, gd )
end

function Unbalance!( fgh :: GMMMarketFGH{T}, gd :: GrumpsData{T} ) where {T<:Flt}
    Unbalance!( fgh.inside, gd )
    @warn "unbalance incomplete for GMM; this only affects standard error computation"
    return nothing
end


function Unbalance!( fgh :: FGH{T}, gd :: GrumpsData{T} ) where {T<:Flt} 
    for m ∈ fgh.market
       Unbalance!( m, gd )
    end
    return nothing
end


