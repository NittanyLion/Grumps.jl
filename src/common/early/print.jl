



printstyledln( xs...; kwargs... ) = printstyled( xs...,"\n"; kwargs... )



function prstyled( io :: IO, adorned :: Bool, xs...; kwargs... )
    if adorned 
        printstyled( io, xs...; kwargs... )
    else
        print( io, xs... )
    end
end

prstyled( adorned :: Bool, xs...; kwargs...) = prstyled( stdout, adorned, xs...; kwargs... )
prstyledln( io :: IO, adorned :: Bool, xs...; kwargs... ) = prstyled( io, adorned, xs..., "\n"; kwargs... )
prstyledln( adorned :: Bool, xs...; kwargs... ) = prstyled( adorned, xs..., "\n"; kwargs... )



function prpair( io :: IO, adorned :: Bool, keyone, keytwo )
    prstyled( io, adorned, @sprintf( "%30s", keyone ) )
    println( io, keytwo )
end


prpair( adorned :: Bool, keyone, keytwo ) = prpair( stdout, adorned, keyone, keytwo )