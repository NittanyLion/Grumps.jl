const todofile = "_test.todo"
const todofp = [ open( todofile, "w" ) ]
const clr = [ :green, :blue, :magenta, :red ]


macro todo( severity :: Int, msg :: String )
    # printstyled( "\n****** $msg *****  $__source__\n\n"; color = clr[severity], bold = true )
    # write( todofp[1], "$severity $msg \n " )
    return nothing
end


