

function CheckInteractionsCallBackFunctionality( ::Val{ :regular }, replicable :: Bool, options :: DataOptions, T ) :: Bool
    if !replicable
        replicable = true
        advisory( "setting replicability to true due to user-defined callback" )
    end
    @ensure hasmethod( Main.InteractionsCallback, ( Matrix{T}, Matrix{T}, Int, Int, Int, Symbol, AbstractString, AbstractVector{AbstractString} ) )  "" *
        "expecting a user-defined method InteractionsCallback with arguments:\n" *
        "z :: Matrix{ $T }\n" *
        "x :: Matrix{ $T }\n" *
        "i :: Int\n" *
        "j :: Int\n" *
        "t :: Int\n" *
        "micmac :: Symbol\n" *
        "market :: Any\n" *
        "products :: Any\n\n" *
        "(types may be omitted)"
    return replicable
end


function CheckInteractionsCallBackFunctionality( ::Val{ :bang }, replicable :: Bool, options :: DataOptions, T ) :: Bool
    if !replicable
        replicable = true
        advisory( "setting replicability to true due to user-defined callback" )
    end
    @ensure hasmethod( Main.InteractionsCallback!, ( Array{T,3}, Matrix{T}, Matrix{T}, Symbol, String, Vector{String} ) )  "" *
        "expecting a (one of two) user-defined method InteractionsCallback! with arguments:\n" *
        "A :: Array{ $T, 3 }\n" *
        "z :: Matrix{ $T }\n" *
        "x :: Matrix{ $T }\n" *
        "micmac :: Symbol\n" *
        "market :: Any\n" *
        "products :: Any\n\n" *
        "(types may be omitted)"

    @ensure hasmethod( Main.InteractionsCallback!, ( Array{T,3}, Matrix{T}, Matrix{T}, Symbol, String, Vector{String} ) )  "" *
    "expecting a (one of two) user-defined method InteractionsCallback! with arguments:\n" *
    "A :: Matrix{ $T }\n" *
    "z :: Matrix{ $T }\n" *
    "x :: Matrix{ $T }\n" *
    "θ :: Vector{ $T }\n"
    "micmac :: Symbol\n" *
    "market :: Any\n" *
    "products :: Any\n\n" *
    "(types may be omitted)"

    return replicable
end



function CheckInteractionsCallBackFunctionality( replicable :: Bool, options :: DataOptions, T ) :: Bool

    isdefined( Main, :InteractionsCallback ) || isdefined( Main, :InteractionsCallback! ) || return replicable
    @ensure micromode( options ) == :Hog "Grumps requires micro data mode :Hog for user-defined interactions callbacks"
    @ensure macromode( options ) == :Ant "Grumps requires macro data mode :Ant for user-defined interactions callbacks"
    isdefined( Main, :InteractionsCallback ) && return CheckInteractionsCallBackFunctionality( Val( :regular ), replicable, options, T )

    return CheckInteractionsCallbackFunctionality( Val( :bang ), replicable, options, T )
end
