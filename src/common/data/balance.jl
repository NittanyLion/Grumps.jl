function computeμσ( μ :: T, σ :: T, count :: Int ) where {T<:Flt}
    μ /= count
    σ = σ / count - μ^2 
    σ = σ > sqrt( eps( T ) ) ? sqrt( σ ) : zero( T )  # PERHAPS I SHOULD EXPOSE THIS CONSTANT
    μ, σ
end




function Balance!( gd :: GrumpsData{T}, scheme :: Val{ :micro } ) where {T<:Flt}
   
    dθ = length( gd.balance )
    activemarkets = findall( x->!( typeof(x.microdata) <: GrumpsMicroNoData ), gd.marketdata )
    dθz = size( gd.marketdata[activemarkets[1]].microdata.Z, 3 )
    # normalize interactions
    @threads for t ∈ 1:dθz
        μ = σ = zero( T )
        count = 0
        for m ∈ activemarkets
            local md = gd.marketdata[m].microdata
            J = size( md.Z, 2 )
            local insides = 1:J-1
            if typeof( md ) <: Union{ GrumpsMicroDataAnt, GrumpsMicroDataHog }
                S = size( md.Z, 1 )
                J = size( md.Z, 2 )
                μ += sum( md.Z[:, insides, t ] )
                σ += sum( md.Z[:, insides, t ].^2 )
                count += (J-1) * S
            else
                @ensure false "Type $(typeof(md)) not yet implemented"
            end
        end
        @ensure count > 1  "need more than one consumer to balance"
        μ, σ = computeμσ( μ, σ, count )
        if σ > zero( T )
            for m ∈ activemarkets
                # gd.marketdata[m].microdata.Z[:,:,t] .-= μ
                gd.marketdata[m].microdata.Z[:,:,t] ./= σ
                # @info "divided Z[:,:,$t] in market $m by $σ"
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
            local md = gd.marketdata[m].microdata
            if typeof( md ) <: GrumpsMicroDataHog 
                R = size( md.X, 1 )
                J = size( md.X, 2 )
                local insides = 1:J-1
                μ += sum( md.X[:, insides, t ] )
                σ += sum( md.X[:, insides, t ].^2 )
                count += (J-1) * R
            elseif typeof( md ) <: GrumpsMicroDataAnt
                J = size( md.𝒳, 1 )
                R = size( md.𝒟, 1 )
                local insides = 1:J-1
                μ += sum( md.𝒳[ j, t ] * md.𝒟[ r, t ] for j ∈ insides, r ∈ 1:R )
                σ += sum( ( md.𝒳[ j, t ] * md.𝒟[ r,t ] )^2 for j ∈ insides, r ∈ 1:R )
                count += (J-1) * R
            end
        end
        @ensure count > 1  "need more than one consumer to balance"
        μ, σ = computeμσ( μ, σ, count )
        if σ > zero( T )
            for m ∈ activemarkets
                # gd.marketdata[m].microdata.X[:,:,t] .-= μ
                gd.marketdata[m].microdata.X[:,:,t] ./= σ
                # @info "divided X[:,:,$t] in market $m by $σ"
            end
        end
        gd.balance[k] = GrumpsNormalization( μ, σ )
    end
    # now rescale the macro end
    @threads for t ∈ 1:dθ
        for m ∈ eachindex( gd.marketdata )
            local Md = gd.marketdata[m].macrodata
            local bal = gd.balance[t]
            tp = typeof( Md  )
            if  tp <: GrumpsMacroNoData 
                continue
            elseif tp <: GrumpsMacroDataHog
                # Md.A[:,:,t] .-= bal.μ
                Md.A[:,:,t] ./= bal.σ
            elseif tp <: GrumpsMacroDataAnt
                # Md.𝒳[:,t] .-= bal.μ
                Md.𝒳[:,t] ./= bal.σ
                # @info "divided 𝒳[:,:,$t] in market $m by $(bal.σ)"
            else
                @ensure false "unknown type"
            end
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
# function Balance!( scheme :: BalancingScheme, gd :: GrumpsData{T} ) where {T<:Flt}
#     if usemicro 
#         @ensure anymicrodata( gd ) "there are no micro data to balance with"
#         return Balance!( scheme, gd, Val( :micro ) )
#     end
#     @ensure anymacrodata( gd ) "there are no macro data to balance with"
#     return Balance!( scheme, gd, Val( :macro ) )
# end
