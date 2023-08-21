
const progresscolor = [ :red, :magenta, :blue, :yellow, :green ]
const progressshape = [ '◌', '◔', '◑', '◕', '●' ]


function done( ρ :: Float64 )
    0 ≤ ρ ≤ 1 || return 1
    return min( Int( round( floor( ρ / 0.2 ) ) ) + 1, 5 )
end


function UpdateProgressBar( ρ )
    ℓ = done( ρ )
    ρ2 = 5ρ - ℓ + 1.0
    s = done( ρ2 )
    c =  done( 5ρ2 - s + 1.0 )
    y,x = displaysize( stdout )
    # Ansillary.Cursor.save() do 
    #     # y, x = Ansillary.Screen.displaysize()
    #     Ansillary.Cursor.move!( Ansillary.Cursor.Coordinate(1,x-5) )
    #     printstyled( progressshape[1]^(5-ℓ); color = progresscolor[1] )
    #     printstyled( progressshape[s]; color = progresscolor[c] )
    #     printstyled( (progressshape[5])^(ℓ-1); color = progresscolor[5] )
    # end     
    Ansillary.Screen.raw() do 
        Ansillary.Cursor.checkpoint() do
            Ansillary.Cursor.move!( Ansillary.Cursor.Coordinate(1,x-5) )
            printstyled( progressshape[1]^(5-ℓ); color = progresscolor[1] )
            printstyled( progressshape[s]; color = progresscolor[c] )
            printstyled( (progressshape[5])^(ℓ-1); color = progresscolor[5] )
        end 
    end
    return nothing
end
