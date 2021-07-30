using Optim
ff(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
function gg!(storage, x)
    storage[1] = -2.0 * (1.0 - x[1]) - 400.0 * (x[2] - x[1]^2) * x[1]
    storage[2] = 200.0 * (x[2] - x[1]^2)
end
function hh!(storage, x)
    storage[1, 1] = 2.0 - 400.0 * x[2] + 1200.0 * x[1]^2
    storage[1, 2] = -400.0 * x[1]
    storage[2, 1] = -400.0 * x[1]
    storage[2, 2] = 200.0
end
using TimerOutputs
const to = TimerOutput()

f(x    ) =  @timeit to "f"  ff(x)
g!(x, g) =  @timeit to "g!" gg!(x, g)
h!(x, h) =  @timeit to "h!" hh!(x, h)

begin
reset_timer!(to)
@timeit to "Trust Region" begin
    res = Optim.optimize(f, g!, h!, zeros(2), NewtonTrustRegion())
end
show(to; allocations = false)
end