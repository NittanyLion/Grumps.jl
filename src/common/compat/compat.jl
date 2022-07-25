
IsCompatible( :: Estimator, :: DefaultMicroIntegrator ) = true
IsCompatible( :: Estimator, :: DefaultMacroIntegrator ) = true
IsCompatible( :: Estimator, :: GrumpsIntegrator ) = false
IsCompatible( :: MSMMicroIntegrator, :: Val{:Hog} ) = true
IsCompatible( :: MSMMicroIntegrator, :: Val ) = false


function CheckCompatible( e :: Estimator, i :: BothIntegrators, options :: DataOptions )
    for im ∈ [ microintegrator(i), macrointegrator(i) ]
        @ensure IsCompatible( e, im ) "integrator type $im is incompatible with estimator type $e"
    end
    for mm ∈ [ micromode( options ) ]
        @ensure IsCompatible( microintegrator( i ), Val( mm ) ) "integrator type $i is incompatible with memory mode $mm"
    end
    return nothing
end