function grumpsthreads( iter :: ismth, lbody :: bsmth, N :: Nsmth ) where { ismth, bsmth, Nsmth }
    lidx = iter.args[1]
    range = iter.args[2]
    return quote
        let range = $(esc(range))
            n = $(esc(N))
            lenr = length(range)
            len, rem = divrem( lenr, n )
            if len == 0
                n = rem
                len = 1
                rem = 0
            end
            rv = Vector{Task}(undef, n)
            for yucky ∈ 1:n
                rv[yucky] = Threads.@spawn begin
                    f = firstindex( range ) + ((yucky-1) * len)
                    ℓ = f + len - 1                    
                    if rem > 0
                        if yucky ≤ rem
                            f += yucky - 1
                            ℓ += yucky
                        else
                            f += rem
                            ℓ += rem
                        end
                    end
                    for i ∈ f : ℓ
                        local $(esc(lidx)) = @inbounds range[i]
                        $(esc(lbody))
                    end
                end
            end           
            for yucky ∈ 1:n
                fetch( rv[yucky] )
            end
        end
    end  
end

macro grumpsthreads( n, ex  )
    if n == 1
        return quote
            $(esc(ex))
        end
    end
    grumpsthreads( ex.args[1], ex.args[2], n )
end


