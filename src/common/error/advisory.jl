# the code below is inspired by Base Julia source logging

function printadvisory( left, right = "" ) 
    printstyled( left; color = 46, bold = true )
    println( right )
end

function advisory( message )
    msglines = eachsplit(chomp(convert(String, string(message))::String), '\n')
    msg1, rest = Iterators.peel(msglines)
    printadvisory( "┌ Note: ", msg1 )
    for msg in rest
        printadvisory("│ ", msg )
    end
    printadvisory("└ " )
end