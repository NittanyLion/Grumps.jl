

abstract type UserEnhancement end


abstract type UserInteractions end

struct DefaultUserInteractions <: UserInteractions
end

abstract type UserRandomCoefficients end

struct DefaultUserRandomCoefficients <: UserRandomCoefficients 
end


struct DefaultUserEnhancement <: UserEnhancement
    interactions            ::  Mat{Symbol}
    randomcoefficients      ::  Vec{Symbol}
    interactionnames        ::  Vec{String}
    randomcoefficientnames  ::  Vec{String}
end

function DefaultUserEnhancement( )
    return DefaultUserEnhancement( 
        Mat{Symbol}(undef,0,0),
        Vec{Symbol}(undef,0),
        Vec{String}(undef,0),
        Vec{String}(undef,0)
    )
end

dim( d :: DefaultUserEnhancement, s :: Symbol ) = 0

