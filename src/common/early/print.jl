


printstyledln( xs...; kwargs... ) = printstyled( xs...,"\n"; kwargs... )


function prstyled( adorned :: Bool, xs...; kwargs... )
    if adorned 
        printstyled( xs...; kwargs... )
    else
        print( xs... )
    end
end


prstyledln( adorned :: Bool, xs...; kwargs... ) = prstyled( adorned, xs..., "\n"; kwargs... )



function prpair( adorned :: Bool, keyone, keytwo )
    prstyled( adorned, @sprintf( "%30s", keyone ) )
    println( keytwo )
end