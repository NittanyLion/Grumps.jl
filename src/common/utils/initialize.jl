


function initializelastδ!( s :: GrumpsMicroSpace{T} ) where {T<:Flt}
    s.lastδ .= typemax( T )
    nothing
end


function initializelastδ!( s :: GrumpsMicroNoSpace{T} ) where {T<:Flt}
    nothing
end



function initializelastδ!( s :: GrumpsMacroSpace{T} ) where {T<:Flt}
    s.lastδ .= typemax( T )
    nothing
end


function initializelastδ!( s :: GrumpsMacroNoSpace{T} ) where {T<:Flt}
    nothing
end


function initializelastδ!( s :: GrumpsSpace{T} , m :: Int ) where {T<:Flt}
    initializelastδ!( s.marketspace[m].microspace )    
    initializelastδ!( s.marketspace[m].macrospace )
    nothing
end

